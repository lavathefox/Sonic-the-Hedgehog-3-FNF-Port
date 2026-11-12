set -euo pipefail

if [ ! -d source ]; then
	echo "Rode na raiz do repositorio (pasta 'source' nao encontrada)." >&2
	exit 1
fi

SKIP='source/backend/FS.hx|source/backend/PlatformUtil.hx|source_html5/'

files=$(grep -rlE 'FileSystem\.|File\.(getContent|getBytes|saveContent|saveBytes)|BitmapData\.fromFile|Sound\.fromFile' source --include='*.hx' | grep -Ev "$SKIP" || true)

if [ -z "$files" ]; then
	echo "Nada para alterar."
	exit 0
fi

count=0
for f in $files; do
	before=$(md5sum "$f" | cut -d' ' -f1)

	sed -i -E \
		-e 's/\bFileSystem\.exists\(/FS.exists(/g' \
		-e 's/\bFileSystem\.isDirectory\(/FS.isDirectory(/g' \
		-e 's/\bFileSystem\.readDirectory\(/FS.readDirectory(/g' \
		-e 's/\bFileSystem\.createDirectory\(/FS.createDirectory(/g' \
		-e 's/\bFile\.getContent\(/FS.getContent(/g' \
		-e 's/\bFile\.getBytes\(/FS.getBytes(/g' \
		-e 's/\bFile\.saveContent\(/FS.saveContent(/g' \
		-e 's/\bFile\.saveBytes\(/FS.saveBytes(/g' \
		-e 's/\bBitmapData\.fromFile\(/FS.loadBitmap(/g' \
		-e 's/\bSound\.fromFile\(/FS.loadSound(/g' \
		"$f"

	after=$(md5sum "$f" | cut -d' ' -f1)
	if [ "$before" != "$after" ]; then
		count=$((count + 1))
		echo "alterado: $f"
	fi
done

if [ -f source/import.hx ] && ! grep -q 'import backend.FS;' source/import.hx; then
	printf '\nimport backend.FS;\n' >> source/import.hx
	echo "adicionado 'import backend.FS;' em source/import.hx"
elif [ ! -f source/import.hx ]; then
	echo "AVISO: source/import.hx nao existe; adicione 'import backend.FS;' nos arquivos alterados." >&2
fi

echo
echo "$count arquivo(s) alterado(s)."
echo
echo "Ainda precisam de revisao manual (nao tocados pelo script):"
grep -rnE 'File\.(write|append|read)\(|FileSystem\.(rename|deleteFile|deleteDirectory|stat|fullPath|absolutePath)\(' source --include='*.hx' \
	| grep -Ev "$SKIP" || echo "  (nenhum)"
