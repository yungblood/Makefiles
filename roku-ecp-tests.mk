#########################################################################
# include file for ECP Tests
#
# Makefile Common Usage:
# > make ecp-test TEST=sample-test.php PARMS="?contentId=1234"
##########################################################################
ecp-test: install
	@if [ "$(TEST)" ]; \
	then \
		echo "Starting $(TEST) test on host $(ROKU_DEV)"; \
		cd exclude/roku-ecp-tests; \
		./$(TEST) $(ROKU_DEV) dev $(PARMS); \
	else \
		echo "Test not selected"; \
		echo 'make ecp-test TEST=sample-test.php PARMS="?contentId=1234"'; \
	fi 
