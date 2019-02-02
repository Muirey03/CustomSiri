GO_EASY_ON_ME=1

ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CustomSiri
CustomSiri_FILES = Tweak.xm
CustomSiri_FRAMEWORKS = UIKit
CustomSiri_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
