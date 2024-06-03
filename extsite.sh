#!/bin/bash

# Autor: Gabriel Claudino
# License: MIT
# Version: 1.0

# Recebe o input da URL
URL=$(dialog --title "EXTRAÇÃO DE DADOS" --inputbox "Insira a URL de um vídeo no Youtube" 10 55 --stdout)

# Verifica se o usuário pressionou Cancelar ou a janela foi fechada
if [ -z "$URL" ]; then
    dialog --msgbox "Nenhuma URL fornecida. Encerrando o script." 5 35
    clear
    exit 1
fi

# Faz o download do conteúdo da página usando lynx e salva em um arquivo temporário
lynx -dump -source "$URL" > site.html

# Verifica se o arquivo foi criado e contém dados
if [ ! -s site.html ]; then
    echo "Falha ao obter o conteúdo da URL: $URL"
    exit 1
fi

# Array para armazenar as informações selecionadas
selected_info=()

# Função para extrair as informações selecionadas
extract_info() {
    for item in "$@"; do
        case "$item" in
            "Título") selected_info+=("Título do vídeo: $title") ;;
            "Autor") selected_info+=("Autor: $author") ;;
            "Data") selected_info+=("Data de publicação: $date_published") ;;
            "Views") selected_info+=("Número de visualizações: $views") ;;
            "Likes") selected_info+=("Número de likes: $likes") ;;
            "Descrição") selected_info+=("Descrição breve: $description") ;;
        esac
    done
}

# Extrai o título da página
title=$(grep -oP '<meta name="title" content="\K[^"]+' site.html)

# Extrai o número de visualizações
views=$(grep -oP '"viewCount":\{"simpleText":"\K[0-9,]+' site.html)

# Extrai o autor do vídeo
author=$(grep -oP '<link itemprop="name" content="\K[^"]+' site.html)

# Extrai a data de publicação
date_published=$(grep -oP '"publishDate":\{"simpleText":"\K[^"]+' site.html)

# Extrai o número de likes
likes=$(grep -oPm 1 'along with \K\d{1,3}(,\d{3})*' site.html | head -n 1 | sed 's/,//g')

# Extrai a descrição do vídeo
description=$(grep -oP '<meta itemprop="description" content="\K[^"]+' site.html)

# Cria um arquivo de texto com todas as informações extraídas
info_filename=$(echo "${title// /_}_${datetime}_INFOS.txt")
{
    echo "Título do vídeo: $title"
    echo "Autor: $author"
    echo "Data de publicação: $date_published"
    echo "Número de visualizações: $views"
    echo "Número de likes: $likes"
    echo "Descrição: $description"
} > "$info_filename"
echo "Arquivo de informações criado: $info_filename"

# Apresenta o checklist e armazena as opções selecionadas em 'itens'
itens=$(dialog --title "DADOS EXTRAÍDOS" --checklist "Escolha as informações extraídas do vídeo que são de seu interesse" 15 55 6 \
"Título" "Título do vídeo" ON \
"Autor" "Autor do vídeo" ON \
"Data" "Data de publicação" ON \
"Views" "Número de visualizações" ON \
"Likes" "Número de likes" ON \
"Descrição" "Descrição breve" OFF \
--stdout)

# Extrai as informações selecionadas
extract_info $itens

# Exibe as informações selecionadas em uma mensagem
dialog --msgbox "$(printf '%s\n' "${selected_info[@]}")" 15 100
clear

# Renomeia o arquivo site.html para o título do vídeo seguido da data e hora atual
datetime=$(date '+%Y%m%d_%H%M%S')
filename=$(echo "${title// /_}_${datetime}.html")
mv site.html "$filename"

# Compacta o arquivo renomeado para o formato .zip
zip "${filename}.zip" "$filename" "$info_filename"

# Cria uma pasta backup se ela não existir
mkdir -p backup

# Move o arquivo compactado para a pasta backup
mv "${filename}.zip" backup/

# Remove o arquivo HTML renomeado
rm "$filename" "$info_filename"

# Confirmação da operação
dialog --title "FIM DA EXECUÇÃO" --msgbox "Arquivo salvo como ${filename}.zip e movido para a pasta backup." 10 50
clear


