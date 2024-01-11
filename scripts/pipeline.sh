
# Sustitución del bucle de descarga por una linea con wget.
wget -i data/urls -P data/


# Variable para la descarga de contaminantes
contaminants_url="https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz"


# Descargar contaminantes y filtrarlos
if [ ! -e "res/contaminants.fasta" ]; then
	bash scripts/download.sh "$contaminants_url" res yes
else
	echo "Skip filtering operation."
fi

# Verificar si el directorio contaminants_idx existe, si no, crearlo
if [ ! -d "res/contaminants_idx" ]; then
    mkdir -p "res/contaminants_idx"
fi


# Indexar los contaminantes
if [ -n "$(ls -A res/contaminants_idx/ )" ]; then
    echo "Skip indexing operation"
else
	bash scripts/index.sh res/contaminants.fasta res/contaminants_idx
fi

# Verificar si el directorio merged existe, si no, crearlo
if [ ! -d "out/merged" ]; then
    mkdir -p "out/merged"
fi


# Unir los datos en un solo archivo.

if [ -n "$(ls -A out/merged/ )" ]; then
    echo "Skip merging operation"
else
    for sid in $(ls data/*.fastq.gz | cut -d "." -f1 | sed 's:data/::' | sort | uniq); do
    	bash scripts/merge_fastqs.sh data out/merged $sid
	done

fi

# Verificar si el directorio trimmed y cutadapt existen, si no, crearlos
if [ ! -d "out/trimmed" ]; then
    mkdir -p "out/trimmed"
fi

if [ ! -d "log/cutadapt" ]; then
    mkdir -p "log/cutadapt"
fi


# Cutadapt para los archivos unidos y guardados en merged
if [ -n "$(ls -A log/cutadapt/ )" ]; then
    echo "Skip cutadapt operation"
else
	for file in out/merged/*.fastq.gz; do
	  file=$(basename "$file" .fastq.gz)
	  cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
		-o out/trimmed/"$file".trimmed.fastq.gz out/merged/"$file".fastq.gz > log/cutadapt/"$file".log
	done
fi


# Verificar si el directorio star existe, si no, crearlo
if [ ! -d "out/star" ]; then
    mkdir -p "out/star"
fi

# Star para los archivos sin adaptadores, creando sus directorios correspondientes
if [ -n "$(ls -A out/star/ )" ]; then
    echo "Skip star operation"
else
	for fname in out/trimmed/*.fastq.gz; do
	  sampleid=$(basename "$fname" .trimmed.fastq.gz)
	  if [ ! -d "out/star/$sampleid" ]; then
		mkdir -p "out/star/$sampleid"
	  fi

	  STAR --runThreadN 4 --genomeDir res/contaminants_idx \
		--outReadsUnmapped Fastx --readFilesIn "$fname" \
		--readFilesCommand gunzip -c --outFileNamePrefix "out/star/$sampleid/"
	done
fi
 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
