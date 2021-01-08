TEST_FILES=*.sh

ifeq (, $(shell which shunit2))
  $(error "Error: shunit2 is not available in PATH")
endif

test: $(TEST_FILES)
	@$(foreach f,$^,./$(f) &&) echo "All tests passed."

.PHONY: test
