#!/bin/bash

# Colores y transparencias para los filtros
# Formato: color:transparencia
# (transparencia 0 = nada, 1 = opaco)
declare -a filters=(
  "none:0"        # _theme0  → sin filtro
  "#ff0000:0.25"  # _theme1  → rojo suave
  "#00ff00:0.25"  # _theme2  → verde suave
  "#0000ff:0.25"  # _theme3  → azul suave
  "#ffff00:0.25"  # _theme4  → amarillo suave
)

# Lista de archivos originales
files=(
  "borders_landscape.png"
  "borders_portrait.png"
  "road_landscape.png"
  "road_portrait.png"
)

# Generar las copias
for file in "${files[@]}"; do
  base="${file%.png}"

  for i in {0..4}; do
    output="${base}_${i}.png"

    IFS=":" read -r color alpha <<< "${filters[$i]}"

    if [ "$color" = "none" ]; then
      # Copia sin filtro
      cp "$file" "$output"
    else
      # Crear filtro de color con transparencia
      convert "$file" \
        \( -size "$(identify -format '%wx%h' "$file")" xc:"$color" -alpha set -channel A -evaluate multiply "$alpha" \) \
        -compose over -composite \
        "$output"
    fi

    echo "Creado: $output"
  done
done
