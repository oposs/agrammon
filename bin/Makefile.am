dist_bin_SCRIPTS = $(MJ_SCRIPT).raku

# make sure we have all Raku dependencies
# pre-compile
install-exec-hook:
	zef --/test --deps-only install ..
	raku -I$(libdir) -c $(bindir)/$(MJ_SCRIPT).raku
