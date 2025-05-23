#import "CalljmpStore.h"

@implementation CalljmpStore

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"calljmp_store"
            binaryMessenger:[registrar messenger]];
  CalljmpStore* instance = [[CalljmpStore alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"securePut" isEqualToString:call.method]) {
    [self securePut:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)securePut:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString *key = call.arguments[@"key"];
  NSString *value = call.arguments[@"value"];
  if (!key || !value) {
    result([FlutterError errorWithCode:@"invalid_params"
                               message:@"Both key and value must be provided"
                               details:nil]);
    return;
  }

  NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];

  NSMutableDictionary *query = [NSMutableDictionary dictionary];
  [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
  [query setObject:key forKey:(__bridge id)kSecAttrAccount];
  [query setObject:valueData forKey:(__bridge id)kSecValueData];
  [query setObject:@YES forKey:(__bridge id)kSecAttrIsInvisible];

  SecItemDelete((__bridge CFDictionaryRef)query);

  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
  
  if (status == errSecSuccess) {
    result(@YES);
  } else {
    NSString *errorMessage = [NSString stringWithFormat:@"Failed to store item: %d", (int)status];
    result([FlutterError errorWithCode:@"keychain_error"
                               message:errorMessage
                               details:nil]);
  }
}

- (void)secureGet:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString *key = call.arguments[@"key"];
  if (!key) {
    result([FlutterError errorWithCode:@"invalid_params"
                               message:@"Key must be provided"
                               details:nil]);
    return;
  }

  NSMutableDictionary *query = [NSMutableDictionary dictionary];
  [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
  [query setObject:key forKey:(__bridge id)kSecAttrAccount];
  [query setObject:@YES forKey:(__bridge id)kSecReturnData];
  [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

  CFDataRef resultData = NULL;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&resultData);
  
  if (status == errSecSuccess && resultData) {
    NSString *value = [[NSString alloc] initWithData:(__bridge_transfer NSData *)resultData
                                             encoding:NSUTF8StringEncoding];
    result(value);
  } else if (status == errSecItemNotFound) {
    result([NSNull null]);
  } else {
    NSString *errorMessage = [NSString stringWithFormat:@"Failed to retrieve item: %d", (int)status];
    result([FlutterError errorWithCode:@"keychain_error"
                                message:errorMessage
                                details:nil]);
  }
}

- (void)secureDelete:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString *key = call.arguments[@"key"];
  if (!key) {
    result([FlutterError errorWithCode:@"invalid_params"
                               message:@"Key must be provided"
                               details:nil]);
    return;
  }

  NSMutableDictionary *query = [NSMutableDictionary dictionary];
  [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
  [query setObject:key forKey:(__bridge id)kSecAttrAccount];

  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
  
  if (status == errSecSuccess || status == errSecItemNotFound) {
    result(@YES);
  } else {
    NSString *errorMessage = [NSString stringWithFormat:@"Failed to delete item: %d", (int)status];
    result([FlutterError errorWithCode:@"keychain_error"
                                message:errorMessage
                                details:nil]);
  }
}

@end
