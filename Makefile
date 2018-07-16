all: zenon_modulo.tar

zenon_modulo.tar: translate_all.sh
	@./$< -j 4

clean: translate_all.sh
	@./$< -c
	@rm -f *~

distclean: clean
	@rm -f zenon_modulo.tar
