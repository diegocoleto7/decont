
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


# TODO: run cutadapt for all merged files
# cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
#     -o <trimmed_file> <input_file> > <log_file>

# TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=#TODO
    # mkdir -p out/star/$sid
    # STAR --runThreadN 4 --genomeDir res/contaminants_idx \
    #    --outReadsUnmapped Fastx --readFilesIn <input_file> \
    #    --readFilesCommand gunzip -c --outFileNamePrefix <output_directory>
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
