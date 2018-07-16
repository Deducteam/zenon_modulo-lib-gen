#!/bin/bash

# URL to the BWare benchmark (as prefix and suffix).
BWARE_URL="http://bware.lri.fr/images/5/50/BWare_PO_v1_TFF1.tgz"

# URL to the Zenon Modulo snapshot.
ZENON_URL="https://scm.gforge.inria.fr/anonscm/gitweb?p=zenon/\
zenon.git;a=snapshot;h=5b26243546dd4fd432316eab51ed5198f9558cea;sf=tgz"

# Number of processes to use for the translation.
NBJOBS=1

# Maximum time / memory allowed on a single file.
MAXTIME="2s"
MAXMEM="2G"

# Show some usage message.
function usage(){
  echo "Usage: $0 [OPTIONS]"
  echo "Available OPTIONS:"
  echo "  -j N        uses N processes (default is 1),"
  echo "  -t N[smhd]  time limit of N seconds/minutes/hours/days per file,"
  echo "  -m N[kMGT]  memory limit of N kilo/mega/giga/tera bytes per file,"
  echo "  -c          cleanup the temporary files,"
  echo "  -h          displays this helpful message."
  echo "Example of use (8 processes, 10 seconds and 2GB of RAM per file):"
  echo "  $0 -j 8 -t 10s -m 2G"
}

# Command line option parsing.
while getopts ":hcj:t:m:" OPT
do
  case $OPT in
    j)
      NBJOBS="$OPTARG"
      if [ "$NBJOBS" -eq "$NBJOBS" ] 2> /dev/null; then
        if [ "$NBJOBS" -lt "1" ] 2> /dev/null; then
          echo "The -j option expects a number greater or equal to 1..."
          exit 1
        fi
      else
        echo "The -j option expects a number..."
        exit 1
      fi
      ;;
    t)
      MAXTIME="$OPTARG"
      case "${MAXTIME: -1}" in
        s|m|h|d)
          ;;
        ?)
          echo "Invalid argument for the -t option..."
          exit 1
          ;;
      esac
      VALUE="${MAXTIME%?}"
      if [ "$VALUE" -eq "$VALUE" ] 2> /dev/null; then
        if [ "$VALUE" -lt "1" ] 2> /dev/null; then
          echo "The -t option expects a number greater or equal to 1..."
          exit 1
        fi
      else
        echo "The -t option expects an argument..."
        exit 1
      fi
      ;;
    m)
      MAXMEM="$OPTARG"
      case "${MAXMEM: -1}" in
        k|M|G|T)
          ;;
        ?)
          echo "Invalid argument for the -t option..."
          exit 1
          ;;
      esac
      VALUE="${MAXMEM%?}"
      if [ "$VALUE" -eq "$VALUE" ] 2> /dev/null; then
        if [ "$VALUE" -lt "1" ] 2> /dev/null; then
          echo "The -t option expects a number greater or equal to 1..."
          exit 1
        fi
      else
        echo "The -t option expects an argument..."
        exit 1
      fi
      ;;
    c)
      echo "Cleaning up..."
      rm -rf bware zenon_modulo zenon_modulo.tar
      exit 0
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      echo "Invalid option..."
      usage
      exit 1
      ;;
  esac
done

# Summary of options.
echo "Running with $NBJOBS processes, $MAXTIME of time and $MAXMEM of RAM."

# Cleaning up.
echo "Cleaning up..."
rm -rf bware zenon_modulo zenon_modulo.tar

# Download the BWare files (only keep the ".p" in a flat directory).
echo "Downloading BWare..."
mkdir -p bware
wget -q -O - $BWARE_URL |
  tar -C bware -zxf - --wildcards "*.p" --strip=2

# Download the theory files from Zenon Modulo and preparing the archive.
echo "Downloading theory files..."
mkdir -p zenon_modulo/logic zenon_modulo/files
wget -q -O - $ZENON_URL |
  tar -C zenon_modulo/logic -zxf - --wildcards "*.dk" --strip=1

# Processing the files.
echo "Processing files..."

function translate_file() {
  INPUT="$1"
  OUTPUT="zenon_modulo/files/$(basename $INPUT .p).dk"

  if zenon_modulo -itptp -modulo -modulo-heuri -odk -max-time $MAXTIME \
    -max-size $MAXMEM $INPUT > $OUTPUT 2> /dev/null
  then 
    gzip $OUTPUT
    echo "Generated the file [$OUTPUT.gz]"
  else
    echo "Unable to find a proof for [$INPUT]"
    touch "zenon_modulo/files/$(basename $INPUT .p).failed"
    rm $OUTPUT
  fi
}

export readonly MAXTIME=$MAXTIME
export readonly MAXMEM=$MAXMEM
export -f translate_file
find bware -type f |
  head -n 100 |
  xargs -P $NBJOBS -n 1 -I{} bash -c "translate_file {}"

# Producing generation data and cleaning up ".failed" files.
echo "Producing generation data..."
NBALL="`ls zenon_modulo/files | wc -l`"
NB_KO="`ls zenon_modulo/files | grep "failed$" | wc -l`"
NB_OK="`ls zenon_modulo/files | grep -v "failed$" | wc -l`"

echo "Generation date    : `date -R`" > zenon_modulo/generation_data.txt
echo "Number of processes: $NBJOBS"  >> zenon_modulo/generation_data.txt
echo "Maximum time       : $MAXTIME" >> zenon_modulo/generation_data.txt
echo "Maximum memory     : $MAXMEM"  >> zenon_modulo/generation_data.txt
echo "Number of files    : $NBALL"   >> zenon_modulo/generation_data.txt
echo "Number of success  : $NB_OK"   >> zenon_modulo/generation_data.txt
echo "Number of failures : $NB_KO"   >> zenon_modulo/generation_data.txt
echo "Failed on files    :"          >> zenon_modulo/generation_data.txt

for FILE in `find zenon_modulo/files -type f -name "*.failed"`
do
  ORIG="$(basename $FILE .failed).p"
  echo "$ORIG" >> zenon_modulo/generation_data.txt
  rm -f $FILE
done

# Creating the archive and cleaning up.
echo "Creating the archive and cleaning up..."
tar -cf zenon_modulo.tar zenon_modulo
rm -rf zenon_modulo bware

echo "All done."
tar -xOf zenon_modulo.tar zenon_modulo/generation_data.txt | head -n 7
