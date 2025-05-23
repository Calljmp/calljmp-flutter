#import <DeviceCheck/DeviceCheck.h>
#import <CommonCrypto/CommonDigest.h>

#import "CalljmpDevice.h"

@implementation CalljmpDevice {
  DCAppAttestService *_attestService;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    if (@available(iOS 14.0, *)) {
      _attestService = [[DCAppAttestService alloc] init];
    }
  }
  return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"calljmp_device"
            binaryMessenger:[registrar messenger]];
  CalljmpDevice* instance = [[CalljmpDevice alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"appleGenerateAttestationKey" isEqualToString:call.method]) {
    [self generateAttestationKey:call result:result];
  } else if ([@"appleAttestKey" isEqualToString:call.method]) {
    [self attestKey:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)generateAttestationKey:(FlutterMethodCall*)call result:(FlutterResult)result {
  if (@available(iOS 14.0, *)) {
    if (![_attestService isSupported]) {
      result([FlutterError errorWithCode:@"unsupported"
                                 message:@"Unsupported device check"
                                 details:nil]);
      return;
    }

    [_attestService generateKeyWithCompletionHandler:^(NSString * _Nullable keyId, NSError * _Nullable error) {
      if (error) {
        result([FlutterError errorWithCode:@"notGenerated"
                                   message:@"Failed to generate key"
                                   details:error]);
        return;
      }
      result(keyId);
    }];
  } else {
    result([FlutterError errorWithCode:@"unsupported"
                               message:@"Unsupported device check"
                               details:nil]);
  }
}

- (void)attestKey:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (@available(iOS 14.0, *)) {
    if (![_attestService isSupported]) {
      result([FlutterError errorWithCode:@"unsupported"
                                 message:@"Unsupported device check"
                                 details:nil]);
      return;
    }

    NSString *keyId = call.arguments[@"keyId"];
    NSString *data = call.arguments[@"data"];

    NSData *dataBytes = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *hashData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(dataBytes.bytes, static_cast<CC_LONG>(dataBytes.length), static_cast<unsigned char*>(hashData.mutableBytes));

    [_attestService attestKey:keyId clientDataHash:hashData completionHandler:^(NSData * _Nullable attestationObject, NSError * _Nullable error) {
      if (error) {
        result([FlutterError errorWithCode:@"attestationFailed"
                                   message:@"Failed to attest key"
                                   details:error]);
        return;
      }

      NSString *attestationString = [attestationObject base64EncodedStringWithOptions:0];
      NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];

      result(@{
        @"keyId": keyId,
        @"bundleId": bundleId,
        @"attestation": attestationString
      });
    }];
  } else {
    result([FlutterError errorWithCode:@"unsupported"
                               message:@"Unsupported device check"
                               details:nil]);
  }
}

@end
