//
//  KeyboardViewController.m
//  Yo Keyboard
//
//  Created by Mathew Hartley on 19/06/14.
//  Copyright (c) 2014 Mathew Hartley. All rights reserved.
//

#import "KeyboardViewController.h"

#define DEFINE_WEAK_SELF __weak typeof(self) wself = self;
#define DEFINE_STRONG_SELF __strong typeof(wself) sself = wself;

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface KeyboardViewController ()
@property (nonatomic, strong) UIButton *nextKeyboardButton;
@property (nonatomic, strong) UIButton *yoButton;

@property (strong) GCDAsyncSocket *socket;
@property (strong) dispatch_queue_t queue;

@end

@implementation KeyboardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Perform custom initialization work here
    }
    return self;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    // Add custom view sizing constraints here
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Perform custom UI setup here
    self.nextKeyboardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [self.nextKeyboardButton setTitle:NSLocalizedString(@"Next Keyboard", @"Title for 'Next Keyboard' button") forState:UIControlStateNormal];
    [self.nextKeyboardButton sizeToFit];
    self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.nextKeyboardButton addTarget:self action:@selector(advanceToNextInputMode) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.nextKeyboardButton];
    
    NSLayoutConstraint *nextKeyboardButtonLeftSideConstraint = [NSLayoutConstraint constraintWithItem:self.nextKeyboardButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint *nextKeyboardButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:self.nextKeyboardButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraints:@[nextKeyboardButtonLeftSideConstraint, nextKeyboardButtonBottomConstraint]];
    
    [self initYoButtonView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"viewWillAppear");
    [self.yoButton setBackgroundColor:UIColorFromRGB(0xdc5500)];

    self.queue = dispatch_queue_create("com.daumcorp.mvoip.socket", DISPATCH_QUEUE_SERIAL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.queue];
    
    DEFINE_WEAK_SELF;
    dispatch_async(self.queue, ^{ @autoreleasepool {
        DEFINE_STRONG_SELF;
        NSError *error = nil;
        [sself.socket connectToHost:@"172.26.36.82" onPort:3193 withTimeout:-1 error:&error];
        if (error != nil)
            return;
    }});

}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"viewWillDisappear");

    DEFINE_WEAK_SELF;
    dispatch_async(self.queue, ^{ @autoreleasepool {
        DEFINE_STRONG_SELF;
        [sself.socket disconnect];
    }});
}

- (void)initYoButtonView {
    self.yoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.yoButton setBackgroundColor:UIColorFromRGB(0xdc5500)];
    
    [self.yoButton setTitle:@"Desktop Keyboard" forState:UIControlStateNormal];
    
    [self.yoButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:30.0]];
    
    [self.yoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.yoButton addTarget:self action:@selector(enterYoText) forControlEvents:UIControlEventTouchUpInside];
    
    self.yoButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.inputView addSubview:self.yoButton];
    
    // initialize
    NSLayoutConstraint *width =[NSLayoutConstraint
                                constraintWithItem:self.yoButton
                                attribute:NSLayoutAttributeWidth
                                relatedBy:0
                                toItem:self.inputView
                                attribute:NSLayoutAttributeWidth
                                multiplier:1.0
                                constant:0];
    NSLayoutConstraint *height =[NSLayoutConstraint
                                 constraintWithItem:self.yoButton
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:0
                                 toItem:self.inputView
                                 attribute:NSLayoutAttributeHeight
                                 multiplier:0.9
                                 constant:0];
    NSLayoutConstraint *top = [NSLayoutConstraint
                               constraintWithItem:self.yoButton
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                               toItem:self.inputView
                               attribute:NSLayoutAttributeTop
                               multiplier:1.0f
                               constant:0.f];
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:self.yoButton
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.inputView
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1.0f
                                   constant:0.f];
    [self.inputView addConstraint:width];
    [self.inputView addConstraint:height];
    [self.inputView addConstraint:top];
    [self.inputView addConstraint:leading];
}

- (void)enterYoText
{
    //[self.textDocumentProxy insertText:@"Yo 12 가나다라"];
    NSLog(@"Yo");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated
}

- (void)textWillChange:(id<UITextInput>)textInput
{
    // The app is about to change the document's contents. Perform any preparation here.
}

- (void)textDidChange:(id<UITextInput>)textInput
{
    // The app has just changed the document's contents, the document context has been updated.
    
    UIColor *textColor = nil;
    if (self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearanceDark)
        textColor = [UIColor whiteColor];
    else
        textColor = [UIColor blackColor];

    [self.nextKeyboardButton setTitleColor:textColor forState:UIControlStateNormal];
}

#pragma - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port;
{
    [self.socket readDataWithTimeout:-1 tag:0];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.yoButton setBackgroundColor:UIColorFromRGB(0xB8D4E5)];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
{
    NSString* readString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];  //not null-terminated data
    //NSString* readString = [NSString stringWithUTF8String:[data bytes]];                      //    null-terminated data
    
    NSLog(@"Received data:%@ (%lu bytes) tag:%ld", readString, data.length, tag);
    [self.socket readDataWithTimeout:-1 tag:0];
    
    [self.textDocumentProxy insertText:readString];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.yoButton setBackgroundColor:UIColorFromRGB(0xdc5500)];
    });

    self.socket = nil;
}



@end
