// GPS Plus Pro - WolFox
// واجهة عائمة آمنة لعرض الخريطة وحفظ إحداثيات تجريبية داخل الواجهة فقط.
// ملاحظة: تم تعطيل أي Hook على CLLocation حتى لا يتم تغيير سلوك النظام أو التطبيقات.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define GPSPLUS_NAME @"WolFox GPS Plus"
#define GPSPLUS_DEFAULT_LAT 24.7136
#define GPSPLUS_DEFAULT_LON 46.6753

@interface GPSPlusStore : NSObject
@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
+ (instancetype)shared;
- (void)load;
- (void)save;
@end

@implementation GPSPlusStore
+ (instancetype)shared {
    static GPSPlusStore *s = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [GPSPlusStore new];
        [s load];
    });
    return s;
}

- (void)load {
    NSUserDefaults *u = NSUserDefaults.standardUserDefaults;
    self.enabled = [u boolForKey:@"WolFox_GPS_Enabled"];
    double lat = [u objectForKey:@"WolFox_GPS_Lat"] ? [u doubleForKey:@"WolFox_GPS_Lat"] : GPSPLUS_DEFAULT_LAT;
    double lon = [u objectForKey:@"WolFox_GPS_Lon"] ? [u doubleForKey:@"WolFox_GPS_Lon"] : GPSPLUS_DEFAULT_LON;
    self.coordinate = CLLocationCoordinate2DMake(lat, lon);
}

- (void)save {
    NSUserDefaults *u = NSUserDefaults.standardUserDefaults;
    [u setBool:self.enabled forKey:@"WolFox_GPS_Enabled"];
    [u setDouble:self.coordinate.latitude forKey:@"WolFox_GPS_Lat"];
    [u setDouble:self.coordinate.longitude forKey:@"WolFox_GPS_Lon"];
    [u synchronize];
}
@end

@interface GPSPlusOverlay : UIView
@property(nonatomic,strong) UIButton *floatButton;
@property(nonatomic,strong) UIVisualEffectView *panel;
@property(nonatomic,strong) MKMapView *mapView;
@property(nonatomic,strong) UIButton *toggleButton;
@property(nonatomic,strong) UILabel *coordsLabel;
+ (instancetype)shared;
- (void)refreshState;
@end

@implementation GPSPlusOverlay
+ (instancetype)shared {
    static GPSPlusOverlay *v = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        v = [[GPSPlusOverlay alloc] initWithFrame:UIScreen.mainScreen.bounds];
    });
    return v;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self buildUI];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? nil : hit;
}

- (void)buildUI {
    CGFloat sw = self.bounds.size.width;
    CGFloat sh = self.bounds.size.height;

    self.floatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.floatButton.frame = CGRectMake(16, 90, 62, 62);
    self.floatButton.layer.cornerRadius = 31;
    self.floatButton.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.95];
    [self.floatButton setTitle:@"GPS" forState:UIControlStateNormal];
    [self.floatButton setTitleColor:UIColor.systemYellowColor forState:UIControlStateNormal];
    self.floatButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [self.floatButton addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.floatButton];

    CGFloat pw = MIN(sw - 24, 420);
    CGFloat ph = MIN(sh - 90, 700);
    self.panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.panel.frame = CGRectMake((sw - pw) / 2.0, 58, pw, ph);
    self.panel.layer.cornerRadius = 24;
    self.panel.clipsToBounds = YES;
    self.panel.hidden = YES;
    [self addSubview:self.panel];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 14, pw - 40, 32)];
    title.text = GPSPLUS_NAME;
    title.textColor = UIColor.whiteColor;
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    [self.panel.contentView addSubview:title];

    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(16, 62, pw - 32, 300)];
    self.mapView.layer.cornerRadius = 18;
    self.mapView.clipsToBounds = YES;
    [self.panel.contentView addSubview:self.mapView];

    CLLocationCoordinate2D c = GPSPlusStore.shared.coordinate;
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(c, 900, 900) animated:NO];

    self.coordsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 372, pw - 32, 28)];
    self.coordsLabel.textColor = UIColor.secondaryLabelColor;
    self.coordsLabel.textAlignment = NSTextAlignmentCenter;
    self.coordsLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];
    [self.panel.contentView addSubview:self.coordsLabel];

    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleButton.frame = CGRectMake(16, 414, pw - 32, 52);
    self.toggleButton.layer.cornerRadius = 16;
    [self.toggleButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.toggleButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [self.toggleButton addTarget:self action:@selector(togglePreviewMode:) forControlEvents:UIControlEventTouchUpInside];
    [self.panel.contentView addSubview:self.toggleButton];

    UIButton *select = [UIButton buttonWithType:UIButtonTypeSystem];
    select.frame = CGRectMake(16, ph - 72, pw - 32, 54);
    select.layer.cornerRadius = 16;
    select.backgroundColor = UIColor.systemBlueColor;
    [select setTitle:@"📍 حفظ موقع الخريطة" forState:UIControlStateNormal];
    [select setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    select.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [select addTarget:self action:@selector(selectLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.panel.contentView addSubview:select];

    [self refreshState];
}

- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
    [self refreshState];
}

- (void)togglePreviewMode:(UIButton *)button {
    GPSPlusStore.shared.enabled = !GPSPlusStore.shared.enabled;
    [GPSPlusStore.shared save];
    [self refreshState];
}

- (void)selectLocation {
    GPSPlusStore.shared.coordinate = self.mapView.centerCoordinate;
    [GPSPlusStore.shared save];
    [self refreshState];
}

- (void)refreshState {
    BOOL enabled = GPSPlusStore.shared.enabled;
    CLLocationCoordinate2D c = GPSPlusStore.shared.coordinate;
    self.toggleButton.backgroundColor = enabled ? UIColor.systemGreenColor : UIColor.systemBlueColor;
    [self.toggleButton setTitle:(enabled ? @"إيقاف وضع العرض" : @"تشغيل وضع العرض") forState:UIControlStateNormal];
    self.coordsLabel.text = [NSString stringWithFormat:@"%.6f, %.6f", c.latitude, c.longitude];
}
@end

static UIWindow *GPSPlusActiveWindow(void) {
    NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in scenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }

        if (scene.activationState != UISceneActivationStateForegroundActive &&
            scene.activationState != UISceneActivationStateForegroundInactive) {
            continue;
        }

        UIWindowScene *windowScene = (UIWindowScene *)scene;
        UIWindow *fallbackWindow = nil;
        for (UIWindow *window in windowScene.windows) {
            if (!fallbackWindow) {
                fallbackWindow = window;
            }
            if (window.isKeyWindow) {
                return window;
            }
        }
        if (fallbackWindow) {
            return fallbackWindow;
        }
    }
    return nil;
}

__attribute__((constructor))
static void WolFoxInit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *w = GPSPlusActiveWindow();
        if (w) {
            GPSPlusOverlay *overlay = GPSPlusOverlay.shared;
            overlay.frame = UIScreen.mainScreen.bounds;
            [w addSubview:overlay];
        }
    });
}
