// GPS Plus Pro - WolFox
// ملف واحد بامتداد .mm لتويك GPS بواجهة عائمة بسيطة ومنظمة.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <objc/runtime.h>

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
+ (instancetype)shared;
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

    UIButton *toggle = [UIButton buttonWithType:UIButtonTypeSystem];
    toggle.frame = CGRectMake(16, 382, pw - 32, 52);
    toggle.layer.cornerRadius = 16;
    toggle.backgroundColor = GPSPlusStore.shared.enabled ? UIColor.systemGreenColor : UIColor.systemBlueColor;
    [toggle setTitle:(GPSPlusStore.shared.enabled ? @"إيقاف GPS" : @"تشغيل GPS") forState:UIControlStateNormal];
    [toggle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    toggle.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [toggle addTarget:self action:@selector(toggleGPS:) forControlEvents:UIControlEventTouchUpInside];
    [self.panel.contentView addSubview:toggle];

    UIButton *select = [UIButton buttonWithType:UIButtonTypeSystem];
    select.frame = CGRectMake(16, ph - 72, pw - 32, 54);
    select.layer.cornerRadius = 16;
    select.backgroundColor = UIColor.systemBlueColor;
    [select setTitle:@"📍 اختر هذا الموقع" forState:UIControlStateNormal];
    [select setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    select.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [select addTarget:self action:@selector(selectLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.panel.contentView addSubview:select];
}
- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
}
- (void)toggleGPS:(UIButton *)button {
    GPSPlusStore.shared.enabled = !GPSPlusStore.shared.enabled;
    [GPSPlusStore.shared save];
    button.backgroundColor = GPSPlusStore.shared.enabled ? UIColor.systemGreenColor : UIColor.systemBlueColor;
    [button setTitle:(GPSPlusStore.shared.enabled ? @"إيقاف GPS" : @"تشغيل GPS") forState:UIControlStateNormal];
}
- (void)selectLocation {
    GPSPlusStore.shared.coordinate = self.mapView.centerCoordinate;
    [GPSPlusStore.shared save];
}
@end

static CLLocationCoordinate2D (*orig_coordinate)(id self, SEL _cmd);
static CLLocationCoordinate2D hooked_coordinate(id self, SEL _cmd) {
    if (GPSPlusStore.shared.enabled) {
        return GPSPlusStore.shared.coordinate;
    }
    return orig_coordinate ? orig_coordinate(self, _cmd) : CLLocationCoordinate2DMake(0, 0);
}

static void installLocationHook(void) {
    Class cls = objc_getClass("CLLocation");
    Method m = class_getInstanceMethod(cls, @selector(coordinate));
    if (m) {
        orig_coordinate = (CLLocationCoordinate2D (*)(id, SEL))method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_coordinate);
    }
}

__attribute__((constructor))
static void WolFoxInit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        installLocationHook();
        UIWindow *w = UIApplication.sharedApplication.keyWindow;
        if (w) {
            GPSPlusOverlay *overlay = GPSPlusOverlay.shared;
            overlay.frame = UIScreen.mainScreen.bounds;
            [w addSubview:overlay];
        }
    });
}
