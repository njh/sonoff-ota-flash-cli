CURL := curl --fail --silent --show-error --location

FIRMWARE_FILES=$(wildcard *.bin)
SHA256_FILES=$(FIRMWARE_FILES:%.bin=%.bin.sha256)
GENERATED_FILES=$(SHA256_FILES) picnic.min.css index.html

build: $(GENERATED_FILES)

%.bin.sha256: %.bin
	sha256sum --binary $< > $@ 

index.html: build-index.rb
	ruby build-index.rb > $@

picnic.min.css:
	$(CURL) -o $@ 'https://raw.githubusercontent.com/franciscop/picnic/master/picnic.min.css'


clean:
	rm -f $(GENERATED_FILES)


.PHONY: build clean
