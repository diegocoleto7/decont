
# Sustitución del bucle de descarga por una linea con wget.
wget -i data/urls -P data/


# Md5 checks
while read url; do
    file_name=$(basename "$url")
    local_file_path="data/${file_name}"
    md5_url="${url}.md5"

    if [ -e "$local_file_path" ]; then
        computed_md5=$(md5sum "$local_file_path" | awk '{print $1}')
        expected_md5=$(curl -sS "$md5_url" | awk '{print $1}')

        if [ "$computed_md5" == "$expected_md5" ]; then
            echo "MD5 checksum for $file_name is valid."
        else
            echo "MD5 checksum for $file_name is INVALID."
        fi
    else
        echo "File $file_name not found."
    fi
done < "data/urls"


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

 
# Creación del archivo.log con la información resumida.
if [ -e "log/pipeline.log" ]; then
    echo "Skip pipeline.log operation."
else
    touch "log/pipeline.log"

	# Extraer líneas de archivos en log/cutadapt/
	for file in log/cutadapt/*; do
	    if [ -f "$file" ]; then
		echo "Archivo: $file" >> "log/pipeline.log"
		grep -E "Total basepairs processed|Reads with adapters" "$file" >> "log/pipeline.log"
		echo "----------------------------------------------------" >> "log/pipeline.log"
	    fi
	done

	# Extraer líneas de archivos log.final.out en out/star/ls/
	for dir in out/star/*; do
	    if [ -d "$dir" ]; then
		file="$dir/Log.final.out"
		if [ -f "$file" ]; then
		    echo "Archivo: $file" >> "log/pipeline.log"
		    grep -E "Uniquely mapped reads %|% of reads mapped to multiple loci|% of reads mapped to too many loci" "$file" >> "log/pipeline.log"
		    echo "----------------------------------------------------" >> "log/pipeline.log"
		fi
	    fi
	done
fi
