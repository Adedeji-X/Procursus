ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += p11-kit
P11_VERSION   := 0.23.21
DEB_P11_V     ?= $(P11_VERSION)

p11-kit-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/p11-glue/p11-kit/releases/download/$(P11_VERSION)/p11-kit-$(P11_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,p11-kit-$(P11_VERSION).tar.xz)
	$(call EXTRACT_TAR,p11-kit-$(P11_VERSION).tar.xz,p11-kit-$(P11_VERSION),p11-kit)

ifneq ($(wildcard $(BUILD_WORK)/p11-kit/.build_complete),)
p11-kit:
	@echo "Using previously built p11-kit."
else
p11-kit: p11-kit-setup gettext libtasn1 libffi
	cd $(BUILD_WORK)/p11-kit && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--with-trust-paths=/etc/ssl/certs/cacert.pem \
		--without-systemd
	+$(MAKE) -C $(BUILD_WORK)/p11-kit
	+$(MAKE) -C $(BUILD_WORK)/p11-kit install \
		DESTDIR=$(BUILD_STAGE)/p11-kit
	+$(MAKE) -C $(BUILD_WORK)/p11-kit install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/p11-kit/.build_complete
endif

p11-kit-package: p11-kit-stage
	# p11-kit.mk Package Structure
	rm -rf $(BUILD_DIST)/p11-kit{,-modules} $(BUILD_DIST)/libp11-kit{0,-dev}
	mkdir -p $(BUILD_DIST)/p11-kit/usr/share \
		$(BUILD_DIST)/p11-kit-modules/usr/lib \
		$(BUILD_DIST)/libp11-kit0/usr/lib \
		$(BUILD_DIST)/libp11-kit-dev/usr/{lib,share}
	
	# p11-kit.mk Prep p11-kit
	cp -a $(BUILD_STAGE)/p11-kit/usr/{bin,libexec} $(BUILD_DIST)/p11-kit/usr
	cp -a $(BUILD_STAGE)/p11-kit/usr/share/p11-kit $(BUILD_DIST)/p11-kit/usr/share

	# p11-kit.mk Prep p11-kit-modules
	cp -a $(BUILD_STAGE)/p11-kit/usr/lib/pkcs11 $(BUILD_DIST)/p11-kit-modules/usr/lib

	# p11-kit.mk Prep libp11-kit0
	cp -a $(BUILD_STAGE)/p11-kit/usr/lib/libp11-kit.0.dylib $(BUILD_DIST)/libp11-kit0/usr/lib
	cp -a $(BUILD_STAGE)/p11-kit/etc $(BUILD_DIST)/libp11-kit0

	# p11-kit.mk Prep libp11-kit-dev
	cp -a $(BUILD_STAGE)/p11-kit/usr/lib/!(libp11-kit.0.dylib|pkcs11) $(BUILD_DIST)/libp11-kit-dev/usr/lib
	cp -a $(BUILD_STAGE)/p11-kit/usr/include $(BUILD_DIST)/libp11-kit-dev/usr
	cp -a $(BUILD_STAGE)/p11-kit/usr/share/gtk-doc $(BUILD_DIST)/libp11-kit-dev/usr/share
	
	# p11-kit.mk Sign
	$(call SIGN,p11-kit,general.xml)
	$(call SIGN,p11-kit-modules,general.xml)
	$(call SIGN,libp11-kit0,general.xml)
	
	# p11-kit.mk Make .debs
	$(call PACK,p11-kit,DEB_P11_V)
	$(call PACK,p11-kit-modules,DEB_P11_V)
	$(call PACK,libp11-kit0,DEB_P11_V)
	$(call PACK,libp11-kit-dev,DEB_P11_V)
	
	# p11-kit.mk Build cleanup
	rm -rf $(BUILD_DIST)/p11-kit{,-modules} $(BUILD_DIST)/libp11-kit{0,-dev}

.PHONY: p11-kit p11-kit-package
