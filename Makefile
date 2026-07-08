ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = WolFoxGPSPlus
WolFoxGPSPlus_FILES = GPSPlusPro.mm
WolFoxGPSPlus_FRAMEWORKS = UIKit Foundation CoreLocation MapKit
WolFoxGPSPlus_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
