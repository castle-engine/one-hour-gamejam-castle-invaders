# Extension of executable is determined by target operating system,
# that in turn depends on 1. -T options in CASTLE_FPC_OPTIONS and
# 2. current OS, if no -T inside CASTLE_FPC_OPTIONS. It's easiest to just
# use "fpc -iTO", to avoid having to detect OS (or parse CASTLE_FPC_OPTIONS)
# in the Makefile.
TARGET_OS = $(shell fpc -iTO $${CASTLE_FPC_OPTIONS:-})
EXE_EXTENSION = $(shell if '[' '(' $(TARGET_OS) '=' 'win32' ')' -o '(' $(TARGET_OS) '=' 'win64' ')' ']'; then echo '.exe'; else echo ''; fi)

.PHONY: standalone
standalone:
	@echo 'Target OS detected: "'$(TARGET_OS)'"'
	@echo 'Target OS exe extension detected: "'$(EXE_EXTENSION)'"'
	@echo 'Using castle_game_engine in directory: ' $(CASTLE_ENGINE_PATH)
	fpc $(FPC_OPTIONS) $(shell $(CASTLE_ENGINE_PATH)castle_game_engine/scripts/castle_engine_fpc_options) code/castle_invaders.lpr
	mv code/castle_invaders$(EXE_EXTENSION) .

.PHONY: clean
clean:
	rm -f \
	       castle_invaders      castle_invaders.exe \
	  code/castle_invaders code/castle_invaders.exe \
	  code/libcastle_invaders_android.so \
	  code/castle_invaders.compiled
	find data/ -iname '*~' -exec rm -f '{}' ';'

#FILES := --exclude *.xcf --exclude '*.blend*' data/
# Hack since zip doesn't work with --exclude ?
FILES := data/
WINDOWS_FILES := $(FILES) castle_invaders.exe *.dll
UNIX_FILES    := $(FILES) castle_invaders

.PHONY: release-win32
release-win32: clean standalone
	rm -Rf castle_invaders-win32.zip
	zip -r castle_invaders-win32.zip $(WINDOWS_FILES)

.PHONY: release-linux
release-linux: clean standalone
	rm -Rf castle_invaders-linux-i386.tar.gz
	tar czvf castle_invaders-linux-i386.tar.gz $(UNIX_FILES)
