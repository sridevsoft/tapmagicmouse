//
//  MultitouchBridge.h
//  Declarations for Apple's private MultitouchSupport.framework.
//
//  This is the only way to read raw touch data from a Magic Mouse; there is no
//  public API for it. These declarations are reverse-engineered and are stable
//  in practice, but Apple can change them in any macOS release.
//

#ifndef MultitouchBridge_h
#define MultitouchBridge_h

#import <Foundation/Foundation.h>

typedef struct { float x; float y; } MTPoint;
typedef struct { MTPoint position; MTPoint velocity; } MTReadout;

typedef struct {
    int frame;
    double timestamp;
    int identifier;
    int state;          // 1-4 = finger down, 5-7 = lifting
    int foo3;
    int foo4;
    MTReadout normalized;   // position on the surface, 0.0-1.0
    float size;
    int zero1;
    float angle;
    float majorAxis;
    float minorAxis;
    MTReadout absoluteVector;
    int zero2[2];
    float unk2;
} MTTouch;

typedef void *MTDeviceRef;
typedef int (*MTContactCallbackFunction)(int device, MTTouch *touches, int numTouches, double timestamp, int frame);

#ifdef __cplusplus
extern "C" {
#endif

CFMutableArrayRef MTDeviceCreateList(void);
void MTRegisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTUnregisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTDeviceStart(MTDeviceRef device, int unknown);
void MTDeviceStop(MTDeviceRef device);
bool MTDeviceIsOpaqueSurface(MTDeviceRef device);   // true for Magic Mouse
bool MTDeviceIsBuiltIn(MTDeviceRef device);         // true for a laptop trackpad

#ifdef __cplusplus
}
#endif

#endif /* MultitouchBridge_h */
