ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += tesseract
TESSERACT_VERSION := 4.1.1
DEB_TESSERACT_V   ?= $(TESSERACT_VERSION)

###
# TODO: 
# tesseract-lang package with the rest of the languages.
###

tesseract-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/tesseract-$(TESSERACT_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/tesseract-$(TESSERACT_VERSION).tar.gz \
			https://github.com/tesseract-ocr/tesseract/archive/$(TESSERACT_VERSION).tar.gz
	$(call EXTRACT_TAR,tesseract-$(TESSERACT_VERSION).tar.gz,tesseract-$(TESSERACT_VERSION),tesseract)

ifneq ($(wildcard $(BUILD_WORK)/tesseract/.build_complete),)
tesseract:
	@echo "Using previously built tesseract."
else
tesseract: tesseract-setup leptonica libarchive curl
	cd $(BUILD_WORK)/tesseract && ./autogen.sh
	cd $(BUILD_WORK)/tesseract && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		LEPTONICA_CFLAGS="-I$(BUILD_STAGE)/leptonica/usr/include/leptonica"
	+$(MAKE) -C $(BUILD_WORK)/tesseract
	+$(MAKE) -C $(BUILD_WORK)/tesseract install \
		DESTDIR="$(BUILD_STAGE)/tesseract"
	+$(MAKE) -C $(BUILD_WORK)/tesseract install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/tesseract/.build_complete
endif

tesseract-package: tesseract-stage
  # tesseract.mk Package Structure
	rm -rf $(BUILD_DIST)/libtesseract4 $(BUILD_DIST)/libtesseract-dev $(BUILD_DIST)/tesseract-ocr
	mkdir -p \
		$(BUILD_DIST)/libtesseract-dev/usr/lib \
		$(BUILD_DIST)/tesseract-ocr/usr \
		$(BUILD_DIST)/libtesseract4/usr/{lib,share}

  # tesseract.mk Prep libtesseract-dev
	cp -a $(BUILD_STAGE)/tesseract/usr/include $(BUILD_DIST)/libtesseract-dev/usr
	cp -a $(BUILD_STAGE)/tesseract/usr/lib/!(libtesseract.4.dylib) $(BUILD_DIST)/libtesseract-dev/usr/lib

  # tesseract.mk Prep tesseract-ocr
	cp -a $(BUILD_STAGE)/tesseract/usr/bin $(BUILD_DIST)/tesseract-ocr/usr
	cp -a $(BUILD_STAGE)/tesseract/usr/share/man $(BUILD_DIST)/tesseract-ocr/usr/share

  # tesseract.mk Prep libtesseract4
	cp -a $(BUILD_STAGE)/tesseract/usr/lib/libtesseract.4.dylib $(BUILD_DIST)/libtesseract4/usr/lib
	cp -a $(BUILD_STAGE)/tesseract/usr/share/tessdata $(BUILD_DIST)/libtesseract4/usr/share
	# Just bundle eng and osd with the library.
	wget -q -nc -P $(BUILD_DIST)/libtesseract4/usr/share/tessdata \
		https://github.com/tesseract-ocr/tessdata_fast/raw/4.0.0/eng.traineddata \
		https://github.com/tesseract-ocr/tessdata_fast/raw/4.0.0/osd.traineddata

  # tesseract.mk Sign
	$(call SIGN,libtesseract4,general.xml)
	$(call SIGN,tesseract-ocr,general.xml)

  # tesseract.mk Make .debs
	$(call PACK,libtesseract-dev,DEB_TESSERACT_V)
	$(call PACK,tesseract-ocr,DEB_TESSERACT_V)
	$(call PACK,libtesseract4,DEB_TESSERACT_V)

  # tesseract.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtesseract4 $(BUILD_DIST)/libtesseract-dev $(BUILD_DIST)/tesseract-ocr

.PHONY: tesseract tesseract-package
