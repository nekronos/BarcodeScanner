#include "BarcodeView.h"

@implementation BarcodeView

- (void)didMoveToSuperview {
	if (self.onViewDidAppear != NULL) {
		self.onViewDidAppear();
	}
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateLayers];
}

- (void)updateLayers {
	self.layer.frame = self.bounds;
    for (CALayer* layer in self.layer.sublayers) {
        layer.frame = self.bounds;
    }
}

@end
