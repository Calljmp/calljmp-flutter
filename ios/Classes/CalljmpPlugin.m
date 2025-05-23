#import "CalljmpPlugin.h"
#import "CalljmpDevice.h"
#import "CalljmpStore.h"

@implementation CalljmpPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [CalljmpDevice registerWithRegistrar:registrar];
  [CalljmpStore registerWithRegistrar:registrar];
}

@end
