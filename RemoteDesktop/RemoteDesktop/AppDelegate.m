//
//  AppDelegate.m
//  RemoteDesktop
//
//  Created by csaint on 2015. 6. 29..
//  Copyright (c) 2015년 Daum. All rights reserved.
//

#import "AppDelegate.h"


#define DEFINE_WEAK_SELF __weak typeof(self) wself = self;
#define DEFINE_STRONG_SELF __strong typeof(wself) sself = wself;


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSButton *buttonListen;
@property (weak) IBOutlet NSButton *buttonSend;
@property (weak) IBOutlet NSTextField *textInput;

@property (strong) GCDAsyncSocket* socketListen;
@property (strong) GCDAsyncSocket* socketAccept;
@property (strong) dispatch_queue_t queue;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.buttonSend setEnabled:NO];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{

}

- (IBAction)onListenButtonPressed:(id)sender
{
    if (self.socketListen == nil)
    {
        [self.buttonListen setEnabled:NO];
        [self.buttonListen setTitle:@"ING.."];

        self.queue = dispatch_queue_create("com.daumcorp.mvoip.socket", DISPATCH_QUEUE_SERIAL);
        self.socketListen = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.queue];

        DEFINE_WEAK_SELF;
        dispatch_async(self.queue, ^{ @autoreleasepool {
            DEFINE_STRONG_SELF;
            
            NSError *error = nil;
            [sself.socketListen acceptOnPort:3193 error:&error];

            [sself.buttonListen setEnabled:YES];
            if (error != nil)
                [sself.buttonListen setTitle:@"LISTEN"];
            else
                [sself.buttonListen setTitle:@"STOP"];
        }});
    }
    else
    {
        [self.socketListen disconnect];
        [self.socketAccept disconnect];
        self.socketListen = nil;
        self.socketAccept = nil;
        
        [self.buttonSend setEnabled:NO];
        [self.buttonListen setTitle:@"LISTEN"];
    }
}

- (IBAction)onSendButtonPressed:(id)sender
{
    if (self.socketListen == nil || self.socketAccept == nil)
        return;

    NSString* inputString = [self.textInput stringValue];
    if (inputString.length == 0)
        return;
    
    DEFINE_WEAK_SELF;
    dispatch_async(self.queue, ^{ @autoreleasepool {
        DEFINE_STRONG_SELF;
        [sself.socketAccept writeData:[inputString dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        
        [sself.textInput setStringValue:@""];
    }});
}

#pragma AsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket;
{
    NSLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
    self.socketAccept = newSocket;
    [self.socketAccept readDataWithTimeout:-1 tag:0];
    [self.buttonSend setEnabled:YES];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
{
    NSString* readString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];  //not null-terminated data
    //NSString* readString = [NSString stringWithUTF8String:[data bytes]];                      //    null-terminated data
    
    NSLog(@"Received data:%@ (%lu bytes) tag:%ld", readString, data.length, tag);
    [self.socketAccept readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    if (sock != nil && self.socketAccept == sock)
    {
        self.socketAccept = nil;
        [self.buttonSend setEnabled:NO];
    }
}

@end
