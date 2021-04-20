DEBUG = 0
# FINALPACKAGE = 1

ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = Preferences


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PowerAction

PowerAction_FILES = Tweak.x
PowerAction_CFLAGS = -fobjc-arc
PowerAction_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
