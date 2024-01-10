
# Genoma para indexar
genomefile="$1"

# Directorio para la creacción del indexado
outdir="$2"

# Comando STAR
STAR --runThreadN 4 --runMode genomeGenerate --genomeDir "$outdir" \
 --genomeFastaFiles "$genomefile" --genomeSAindexNbases 9
