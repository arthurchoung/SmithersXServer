#import "HOTDOG.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <netinet/in.h>

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
    return obj;
}
@end

@interface XServer : IvarObject
{
    BOOL _auto;
    int _sequenceNumber;
    int _sockfd;
    int _connfd;
    id _data;
    int _scrollY;
    id _text;

    int _rootWindow;
    int _colormap;
    int _visualStaticGray;
    int _visualTrueColor;
    int _internAtomCounter;
    id _internAtoms;
    id _putImageBitmap;
}
@end
@implementation XServer
- (id)contextualMenu
{
static id str =
@"hotKey,displayName,messageForClick\n"
@"r,sendResponse,sendResponse\n"
@",consumeRequest,consumeRequest\n"
@",parseData,parseData\n"
@",Send connection setup response,sendConnectionSetupResponse\n"
@",sendQueryExtensionResponse,sendQueryExtensionResponse\n"
@",sendGetPropertyResponseNONE,sendGetPropertyResponseNONE\n"
@",sendGetWindowAttributesResponse,sendGetWindowAttributesResponse\n"
@",sendGetGeometryResponse,sendGetGeometryResponse\n"
@",sendInternAtomResponse,sendInternAtomResponse\n"
@",sendQueryTreeResponse,sendQueryTreeResponse\n"
@",sendQueryColorsResponse,sendQueryColorsResponse\n"
@",sendAllocColorResponse,sendAllocColorResponse\n"
@",toggle auto,\"toggleBoolKey:'auto'\"\n"
;
    id menu = [[str parseCSVFromString] asMenu];
    [menu setValue:self forKey:@"contextualObject"];
    return menu;
}

- (id)init
{
    self = [super init];
    if (self) {
        _sockfd = -1;
        _connfd = -1;

        _rootWindow = 99;
        _colormap = 98;
        _visualStaticGray = 97;
        _visualTrueColor = 96;
        _internAtomCounter++;
        [self setValue:nsdict() forKey:@"internAtoms"];
    }
    return self;
}
- (int *)fileDescriptors
{
    static int fds[3];
    int i = 0;
    if (_sockfd >= 0) {
        fds[i] = _sockfd;
        i++;
    }
    if (_connfd >= 0) {
        fds[i] = _connfd;
        i++;
    }
    fds[i] = -1;
    return fds;
}
- (void)handleFileDescriptor:(int)fd
{
    NSLog(@"handleFileDescriptor");

    if (fd == _sockfd) {
        [self handleSocketFileDescriptor];
    } else if (fd == _connfd) {
        [self handleConnectionFileDescriptor];
    }
}

- (void)handleSocketFileDescriptor
{
    if (_sockfd < 0) {
        return;
    }

    if (_connfd < 0) {
        socklen_t addrlen = sizeof(_addr);
        int connfd = accept(_sockfd, (struct sockaddr *)&_addr, &addrlen);
        if (connfd < 0) {
            NSLog(@"accept failed");
            return;
        }

        NSLog(@"connfd %d", connfd);
        _connfd = connfd;
        return;
    }
}
- (void)handleConnectionFileDescriptor
{
    if (_connfd < 0) {
        return;
    }

    if (!_data) {
        [self setValue:[[[NSMutableData alloc] initWithCapacity:1024*1024] autorelease] forKey:@"data"];
    }

    char buf[65536];
    int result = read(_connfd, buf, sizeof(buf));
    if (result > 0) {
        [_data appendBytes:buf length:result];
        [self setValue:nil forKey:@"text"];
        [self parseData];
    } else if (result == 0) {
        close(_connfd);
        _connfd = -1;
    } else {
        close(_connfd);
        _connfd = -1;
        NSLog(@"read error %s", strerror(errno));
    }
}
- (void)drawInBitmap:(id)bitmap rect:(Int4)r
{
    [bitmap useAtariSTFont];
    [bitmap setColor:@"white"];
    [bitmap fillRect:r];
    [bitmap setColor:@"black"];

    int cursorY = r.y+_scrollY;

    if (_putImageBitmap) {
        [bitmap drawBitmap:_putImageBitmap x:r.x y:cursorY];
        cursorY += [_putImageBitmap bitmapHeight];
    }

    id arr = nsarr();

    if (_sequenceNumber) {
        int len = [_data length];
        if (len < 4) {
            [arr addObject:@"not enough data"];
        } else {
            unsigned char *bytes = [_data bytes];

            int opcode = bytes[0];
            int requestLength = read_uint16(bytes+2);
            id text = nsfmt(@"opcode %d (%@) requestLength %d\n", opcode, name_for_opcode(opcode), requestLength);
            [arr addObject:text];
        }
    }


    if (_text) {
        [arr addObject:_text];
    }
    [arr addObject:nsfmt(@"auto %d", _auto)];
    [arr addObject:nsfmt(@"sequenceNumber %d", _sequenceNumber)];
    [arr addObject:nsfmt(@"sockfd %d", _sockfd)];
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
    [bitmap drawBitmapText:text x:r.x+5 y:cursorY+5];
}
- (void)handleScrollWheel:(id)event
{
    _scrollY += [event intValueForKey:@"deltaY"];
}
- (void)clearData
{
    NSLog(@"clearData");
    [_data setLength:0];
}
- (void)consumeRequest
{
    if (!_sequenceNumber) {
        [_data deleteBytesFromIndex:0 length:12];
        _sequenceNumber = 1;
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
    [self setValue:text forKey:@"text"];
    
}
- (void)parseRequest
{
    int len = [_data length];
    if (len < 4) {
        [self setValue:@"not enough data" forKey:@"text"];
        return;
    }
    unsigned char *bytes = [_data bytes];
    unsigned char *p = bytes;

    int opcode = p[0];
    int requestLength = read_uint16(p+2);
    if (len < requestLength*4) {
        [self setValue:@"not enough data" forKey:@"text"];
        return;
    }
    p+=4;

    if (opcode == 98) { //QueryExtension
        int lengthOfName = read_uint16(p);
        p+=2;
        p+=2;
        id name = nil;
        if (lengthOfName) {
            name = nsfmt(@"%.*s", lengthOfName, p);
        }
        id text = nsfmt(
@"opcode %d (QueryExtension)\n"
@"requestLength %d\n"
@"lengthOfName %d\n"
@"name '%@'\n",
opcode, requestLength, lengthOfName, name);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 55) { //CreateGC
        id text = nsfmt(
@"opcode %d (CreateGC)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 20) { //GetProperty
        id text = nsfmt(
@"opcode %d (GetProperty)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 112) { //SetCloseDownMode
        id text = nsfmt(
@"opcode %d (SetCloseDownMode)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 3) { //GetWindowAttributes
        id text = nsfmt(
@"opcode %d (GetWindowAttributes)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 14) { //GetGeometry
        id text = nsfmt(
@"opcode %d (GetGeometry)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 78) { //CreateColormap
        id text = nsfmt(
@"opcode %d (CreateColormap)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 1) { //CreateWindow
        id text = nsfmt(
@"opcode %d (CreateWindow)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 18) { //ChangeProperty
        id text = nsfmt(
@"opcode %d (ChangeProperty)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 16) { //InternAtom
        id text = nsfmt(
@"opcode %d (InternAtom)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 8) { //MapWindow
        id text = nsfmt(
@"opcode %d (MapWindow)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    } else if (opcode == 72) { //PutImage
        [self parsePutImageRequest];
        return;
    } else if (opcode == 15) { //QueryTree
        id text = nsfmt(
@"opcode %d (QueryTree)\n"
@"requestLength %d\n",
opcode, requestLength);
        [self setValue:text forKey:@"text"];
        return;
    }

    id text = nsfmt(
@"opcode %d (unknown)\n"
@"requestLength %d\n",
opcode, requestLength);
    [self setValue:text forKey:@"text"];
}

- (void)parsePutImageRequest
{
    int len = [_data length];
    if (len < 4) {
        [self setValue:@"not enough data" forKey:@"text"];
        return;
    }
    unsigned char *bytes = [_data bytes];
    unsigned char *p = bytes;

    int opcode = p[0];
    int format = p[1];
    int requestLength = read_uint16(p+2);
    if (len < requestLength*4) {
        [self setValue:@"not enough data" forKey:@"text"];
        return;
    }
    p+=4;
    int drawable = read_uint32(p);
    p+=4;
    int gc = read_uint32(p);
    p+=4;
    int width = read_uint16(p);
    p+=2;
    int height = read_uint16(p);
    p+=2;
    int dstX = read_uint16(p);
    p+=2;
    int dstY = read_uint16(p);
    p+=2;
    int leftPad = *p;
    p++;
    int depth = *p;
    p++;
    p+=2;
    if ((depth == 24) || (depth == 32)) {
        if (len >= width*height*4+6*4) {
            id bitmap = [Definitions bitmapWithWidth:width height:height];
            unsigned char *pixelBytes = [bitmap pixelBytes];
            memcpy(pixelBytes, p, width*height*4);
            [self setValue:bitmap forKey:@"putImageBitmap"];
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
        [self setValue:nil forKey:@"putImageBitmap"];
    }

    id text = nsfmt(
@"opcode %d (PutImage)\n"
@"requestLength %d\n"
@"drawable 0x%x\n"
@"gc 0x%x\n"
@"width %d\n"
@"height %d\n"
@"dstX %d\n"
@"dstY %d\n"
@"leftPad %d\n"
@"depth %d\n"
, opcode, requestLength, drawable, gc, width, height, dstX, dstY, leftPad, depth);
    [self setValue:text forKey:@"text"];
}

- (void)sendResponse
{
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
        [self sendQueryExtensionResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 55) { //CreateGC
        [self consumeRequest];
        return;
    } else if (opcode == 16) { //InternAtom
        [self sendInternAtomResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 15) { //QueryTree
        [self sendQueryTreeResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 3) { //GetWindowAttributes
        [self sendGetWindowAttributesResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 14) { //GetGeometry
        [self sendGetGeometryResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 2) { //ChangeWindowAttributes
        [self consumeRequest];
        return;
    } else if (opcode == 91) { //QueryColors
        [self sendQueryColorsResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 84) { //AllocColor
        [self sendAllocColorResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 53) { //CreatePixmap
        [self consumeRequest];
        return;
    } else if (opcode == 72) { //PutImage
        [self consumeRequest];
        return;
    } else if (opcode == 60) { //FreeGC
        [self consumeRequest];
        return;
    } else if (opcode == 54) { //FreePixmap
        [self consumeRequest];
        return;
    } else if (opcode == 43) { //GetInputFocus
        [self sendGetInputFocusResponse];
        [self consumeRequest];
        return;
    } else if (opcode == 92) { //LookupColor
        [self sendLookupColorResponse];
        [self consumeRequest];
        return;
    }

    _auto = 0;
}
- (void)sendConnectionSetupResponse
{
    if (_connfd < 0) {
        return;
    }
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

    //m     LISTofSCREEN                    roots (m is always a multiple of 4)
    //4     WINDOW                          root
    p[0] = _rootWindow;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     COLORMAP                        default-colormap
    p[0] = _colormap;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
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
    p[0] = 0;
    p[1] = 2;
    p+=2;

    //2     CARD16                          height-in-pixels
    p[0] = 0;
    p[1] = 2;
    p+=2;

    //2     CARD16                          width-in-millimeters
    p[0] = 0;
    p[1] = 2;
    p+=2;

    //2     CARD16                          height-in-millimeters
    p[0] = 0;
    p[1] = 2;
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
    p[0] = _visualTrueColor;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
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
    p[0] = 2;
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
    p[0] = _visualStaticGray;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
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
    p[0] = _visualTrueColor;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
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
- (void)sendQueryExtensionResponse
{
    if (_connfd < 0) {
        return;
    }
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
    p[0] = 0;
    p++;

    //1     CARD8                           major-opcode
    p[0] = 0;
    p++;

    //1     CARD8                           first-event
    p[0] = 0;
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
- (void)sendGetPropertyResponseNONE
{
    if (_connfd < 0) {
        return;
    }
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     CARD8                           format
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

    //4     ATOM                            type
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     CARD32                          bytes-after
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     CARD32                          length of value in format units
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //12                                    unused
    memset(p, 0, 12);
    p+=12;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetWindowAttributesResponse
{
    if (_connfd < 0) {
        return;
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
    p[0] = 3;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     VISUALID                        visual
    p[0] = _visualTrueColor;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2                                     class
    //      1     InputOutput
    //      2     InputOnly
    p[0] = 1;
    p[1] = 0;
    p+=2;

    //1     BITGRAVITY                      bit-gravity
    p[0] = 0;
    p++;

    //1     WINGRAVITY                      win-gravity
    p[0] = 1;
    p++;

    //4     CARD32                          backing-planes
    p[0] = 0xff;
    p[1] = 0xff;
    p[2] = 0xff;
    p[3] = 0xff;
    p+=4;

    //4     CARD32                          backing-pixel
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //1     BOOL                            save-under
    p[0] = 0;
    p++;

    //1     BOOL                            map-is-installed
    p[0] = 1;
    p++;

    //1                                     map-state
    //      0     Unmapped
    //      1     Unviewable
    //      2     Viewable
    p[0] = 2;
    p++;

    //1     BOOL                            override-redirect
    p[0] = 0;
    p++;

    //4     COLORMAP                        colormap
    //      0     None
    p[0] = _colormap;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     SETofEVENT                      all-event-masks
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     SETofEVENT                      your-event-mask
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2     SETofDEVICEEVENT                do-not-propagate-mask
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2                                    unused
    p[0] = 0;
    p[1] = 0;
    p+=2;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetGeometryResponse
{
    if (_connfd < 0) {
        return;
    }
    unsigned char buf[256];
    unsigned char *p = buf;

    //1     1                               Reply
    p[0] = 1;
    p++;

    //1     CARD8                           depth
    p[0] = 32;
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

    //4     WINDOW                          root
    p[0] = _rootWindow;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2     INT16                           x
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     INT16                           y
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //2     CARD16                          width
    p[0] = 0;
    p[1] = 2;
    p+=2;

    //2     CARD16                          height
    p[0] = 0;
    p[1] = 2;
    p+=2;

    //2     CARD16                          border-width
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //10                                    unused
    memset(p, 0, 10);
    p+=10;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendInternAtomResponse
{
    if (_connfd < 0) {
        return;
    }
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

    //4     ATOM                            atom
    p[0] = _internAtomCounter;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //20                                    unused
    memset(p, 0, 20);
    p+=20;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);

    [_internAtoms setValue:@"insert name" forKey:nsfmt(@"%d", _internAtomCounter)];
    _internAtomCounter++;
}
- (void)sendQueryTreeResponse
{
    if (_connfd < 0) {
        return;
    }
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

    //4     WINDOW                          root
    p[0] = _rootWindow;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     WINDOW                          parent
    //      0     None
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2     n                               number of WINDOWs in children
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //14                                    unused
    memset(p, 0, 14);
    p+=14;

    //4n     LISTofWINDOW                   children

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendQueryColorsResponse
{
    if (_connfd < 0) {
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

    //4     2n                              reply length
    p[0] = 0;
    p[1] = 2;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2     n                               number of RGBs in colors
    p[0] = 0;
    p[1] = 1;
    p+=2;

    //22                                    unused
    memset(p, 0, 22);
    p+=22;

    //8n     LISTofRGB                      colors
    for (int i=0; i<256; i++) {
        //2     CARD16                          red
        p[0] = 0;
        p[1] = 0;
        p+=2;

        //2     CARD16                          green
        p[0] = 0;
        p[1] = 0;
        p+=2;

        //2     CARD16                          blue
        p[0] = 0;
        p[1] = 0;
        p+=2;

        //2                                     unused
        p[0] = 0;
        p[1] = 0;
        p+=2;
    }

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendAllocColorResponse
{
    if (_connfd < 0) {
        return;
    }

    unsigned char *bytes = [_data bytes];
    unsigned char r = bytes[9];
    unsigned char g = bytes[11];
    unsigned char b = bytes[13];

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
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //2     CARD16                          red
    p[0] = 0;
    p[1] = r;
    p+=2;

    //2     CARD16                          green
    p[0] = 0;
    p[1] = g;
    p+=2;

    //2     CARD16                          blue
    p[0] = 0;
    p[1] = b;
    p+=2;

    //2                                     unused
    p[0] = 0;
    p[1] = 0;
    p+=2;

    //4     CARD32                          pixel
    p[0] = b;
    p[1] = g;
    p[2] = r;
    p[3] = 0;
    p+=4;

    //12                                    unused
    memset(p, 0, 12);
    p+=12;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendGetInputFocusResponse
{
    if (_connfd < 0) {
        return;
    }

    unsigned char *bytes = [_data bytes];
    unsigned char r = bytes[9];
    unsigned char g = bytes[11];
    unsigned char b = bytes[13];

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
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //4     WINDOW                          focus
    //      0     None
    //      1     PointerRoot
    p[0] = 0;
    p[1] = 0;
    p[2] = 0;
    p[3] = 0;
    p+=4;

    //20                                    unused
    memset(p, 0, 20);
    p+=20;

NSLog(@"sending %d bytes", p-buf);
    send(_connfd, buf, p-buf, 0);
}
- (void)sendLookupColorResponse
{
    if (_connfd < 0) {
        return;
    }
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
@end

