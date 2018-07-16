NBWORKERS=4

all: zenon_modulo.tar


bware.tgz:
	wget -q --show-progress -O $@ http://bware.lri.fr/images/5/50/BWare_PO_v1_TFF1.tgz

bware: bware.tgz
	tar -xf $< --transform 's/BWARE_PO_v1_TFF1/$@/'

zenon_modulo.tar: bware translate.sh
	mkdir -p zenon_modulo/logic
	wget -q --show-progress https://gforge.inria.fr/frs/download.php/file/36322/zenon_modulo_0.4.2.tar.gz
	tar -xf zenon_modulo_0.4.2.tar.gz --wildcards "*.dk" --transform 's/zenon_modulo/zenon_modulo\/logic/'
	rm -f zenon_modulo_0.4.2.tar.gz
	mv zenon_modulo/logic/modulogic.dk zenon_modulo/logic/zen.dk
	find bware -name "*.p" | xargs -P ${NBWORKERS} -n 1 -I{} ./translate.sh {} \;
	tar -cf $@ zenon_modulo
	
clean:

distclean: clean
	rm -rf bware bware.tgz zenon_modulo
