#import <UIKit/UIKit.h>

typedef void (^ViewDidAppearHandler)();

@interface BarcodeView : UIView

@property (copy) ViewDidAppearHandler onViewDidAppear;

- (void)updateLayers;

@end