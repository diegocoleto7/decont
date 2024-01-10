
# Argumentos enviados desde pipeline.sh
url="$1"
destination_directory="$2"
extract="$3"

# Descargar el archivo
wget "$url" -P "$destination_directory"

# Verificar si se debe descomprimir
if [ "$extract" = "yes" ]; then
    # Obtener el nombre del archivo descargado
    filename=$(basename "$url")

    # Descomprimir el archivo con gunzip
    if [ "${filename##*.}" = "gz" ]; then
        gunzip -k "$destination_directory/$filename"

        # Filtrar y eliminar secuencias de snRNA con seqkit
        seqkit grep -v -n -r -p "small nuclear" "$destination_directory/${filename%.*}" | seqkit grep -v -n -r -p "snRNA" > "$destination_directory/${filename%.*}_filtered.fasta"
        
        # Reemplazar el archivo original con el filtrado
        mv "$destination_directory/${filename%.*}_filtered.fasta" "$destination_directory/${filename%.*}"
    else
        echo "Error: Format not supported for decompression."
    fi
fi
