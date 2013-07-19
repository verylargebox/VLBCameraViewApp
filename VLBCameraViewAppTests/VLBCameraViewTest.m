//
//  VLBCameraTest.m
//  verylargebox
//
//  Created by Markos Charatzas on 29/06/2013.
//  Copyright (c) 2013 verylargebox.com.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Kiwi/Kiwi.h>
#import <OCMock/OCMock.h>
#import <AVFoundation/AVFoundation.h>
#import "VLBCameraView.h"

//testing
typedef void(^VLBCaptureStillImageBlock)(CMSampleBufferRef imageDataSampleBuffer, NSError *error);

@interface VLBCameraView (Test)
@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property(nonatomic, weak) UIImageView* preview;

-(VLBCaptureStillImageBlock) didFinishTakingPicture:(AVCaptureSession*) session preview:(UIImageView*)preview videoPreviewLayer:(AVCaptureVideoPreviewLayer*) videoPreviewLayer;
@end

@interface VLBCameraViewTestDelegate : NSObject <VLBCameraViewDelegate>
@property(nonatomic, strong) dispatch_group_t group;
@property(nonatomic, strong) NSObject<VLBCameraViewDelegate> *delegate;
@end

@implementation VLBCameraViewTestDelegate

-(void)cameraView:(VLBCameraView *)cameraView didFinishTakingPicture:(UIImage *)image withInfo:(NSDictionary *)info meta:(NSDictionary *)meta{
    
}

-(void)cameraView:(VLBCameraView *)cameraView didErrorOnTakePicture:(NSError *)error{
    [self.delegate cameraView:cameraView didErrorOnTakePicture:error];
    dispatch_group_leave(self.group);
}

@end

@interface VLBCameraViewTest : SenTestCase

@end

@implementation VLBCameraViewTest

@end

SPEC_BEGIN(VLBCameraSpec)

context(@"assert imageview preview will fill its view; given a new VLBCameraView instance, its UIImageView", ^{
    it(@"should have a mode of UIViewContentModeScaleAspectFill and clipToBounds", ^{
        VLBCameraView *cameraView = [[VLBCameraView alloc] initWithFrame:CGRectZero];
        
        [[theValue(cameraView.preview.clipsToBounds) should] equal:theValue(YES)];
        [[theValue(cameraView.preview.contentMode) should] equal:theValue(UIViewContentModeScaleAspectFill)];
    });
});

context(@"assert delegate gets callbacks; given the VLBCaptureStillImageBlock", ^{
    it(@"should callback the VLBCameraView delegate when error", ^{

        id mockedDelegate = [OCMockObject mockForProtocol:@protocol(VLBCameraViewDelegate)];
        dispatch_group_t group = dispatch_group_create();
        VLBCameraViewTestDelegate *delegate = [[VLBCameraViewTestDelegate alloc] init];
        delegate.delegate = mockedDelegate;
        delegate.group = group;
        VLBCameraView *cameraView = [[VLBCameraView alloc] initWithCoder:nil];
        cameraView.delegate = delegate;
        NSError *anyerror = [[NSError alloc] init];
        VLBCaptureStillImageBlock stillImageBlock = [cameraView didFinishTakingPicture:nil preview:nil videoPreviewLayer:nil];
        
        dispatch_group_enter(group);
        
        [[mockedDelegate expect] cameraView:cameraView didErrorOnTakePicture:anyerror];

        stillImageBlock(nil, anyerror);

        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            [mockedDelegate verify];
        });
    });
    it(@"should callback its delegate with image", ^{
        
        id mockedDelegate = [OCMockObject mockForProtocol:@protocol(VLBCameraViewDelegate)];
        id mockedStillImageOutput = [OCMockObject niceMockForClass:[AVCaptureStillImageOutput class]];

        VLBCameraView *cameraView = [[VLBCameraView alloc] initWithCoder:nil];
        cameraView.stillImageOutput = mockedStillImageOutput;
        cameraView.delegate = mockedDelegate;
        VLBCaptureStillImageBlock stillImageBlock = [cameraView didFinishTakingPicture:nil preview:nil videoPreviewLayer:nil];
        
        [[mockedDelegate expect] cameraView:cameraView didFinishTakingPicture:nil withInfo:nil meta:nil];
        stillImageBlock(nil, nil);
        
        [mockedDelegate verify];
    });
});

SPEC_END
