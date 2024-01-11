
# Directorio de entrada
input_dir="$1"

# Directorio de salida
output_dir="$2"

# Identificador de la muestra
sample_id="$3"

# Crear el nombre del archivo de salida
output_file="${output_dir}/${sample_id}.fastq.gz"

# Concatenar los archivos de entrada
cat "${input_dir}/${sample_id}.5dpp.1.1s_sRNA.fastq.gz" "${input_dir}/${sample_id}.5dpp.1.2s_sRNA.fastq.gz"  > "${output_file}"

# Imprimir mensaje
echo "Merged files in: ${output_file}"
