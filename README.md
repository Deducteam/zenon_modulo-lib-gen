Generation script for BWare to Dedukti
======================================

This repository contains a script that can be used to generate dedukti/lambdapi files
from the BWare benchmark files. Note that `zenon_modulo` should be installed
prior to running the script (more specifically, the `modulo` branch for `dedukti` output and `modulo_lp` for `lambdapi` output). It can
be installed using the following command.
```bash
git clone https://github.com/elhaddadyacine/zenon_modulo.git
cd zenon
git checkout modulo #or modulo_lp
./configure
make
su -c "make install"
```

Run the following command to obtain a detailed usage manual.
```bash
./translate_all.sh -h
```

Note that the script produces a `zenon_modulo.tar` file containing a single
directory `zenon_modulo`, itself containing:
 - a directory `logic` containing the theory files (they are required for
   type-checking using Dedukti or Lambdapi),
 - a directory `files` containing the successfully generated Dedukti files,
 - a file `generation_data.txt` containing data about the generation of the
   files, including generation date, the used configuration and the list of
   the files that failed to be generated.

Reasonable options to generate the files are:
```bash
./translate_all.sh -j 4 -t 2s -m 512M
```

Note that the following command can be used to cleanup the directory.
```bash
./translate_all.sh -c
```
