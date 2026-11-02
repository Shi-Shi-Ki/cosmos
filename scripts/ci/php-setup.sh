#!/usr/bin/env bash
# PHP のバージョンを決め、そのバージョンで PHP と composer を実行するラッパー（php-target / composer-target）を用意する。
# バージョンは composer.json の config.platform.php → require.php の下限 → DEFAULT_VERSION の順に決める。
# ランナーの PHP と同じならそれを使い、違えば Docker の公式イメージ php:<version>-cli で実行する。
# 出力（GITHUB_OUTPUT）: found（PHP のファイルがあるか）、version
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

mkdir -p "$RUNNER_TEMP/bin"
if [ ! -f composer.json ] && [ -z "$(git ls-files '*.php' | head -n 1)" ]; then exit 0; fi
echo "found=true" >> "$GITHUB_OUTPUT"

constraint="" source="入力値 php-version"
if [ -f composer.json ]; then
  constraint=$(jq -r '.config.platform.php // empty' composer.json); source="composer.json の config.platform.php"
  if [ -z "$constraint" ]; then constraint=$(jq -r '.require.php // empty' composer.json); source="composer.json の require.php"; fi
fi
version=$(printf '%s' "$constraint" | grep -oE '[0-9]+(\.[0-9]+)?' | head -n 1 || true)
if [ -z "$version" ]; then version=$DEFAULT_VERSION; source="入力値 php-version"; fi
case "$version" in *.*) ;; *) version="$version.0" ;; esac
version=$(printf '%s' "$version" | cut -d. -f1-2)
# リポジトリの内容から決まる値なので、Docker のイメージ名に使う前に形式を確かめる
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then echo "::error::PHP のバージョンを読み取れません: $constraint"; exit 1; fi

runner_version=$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')
composer_bin=$(readlink -f "$(command -v composer)")
if [ "$version" = "$runner_version" ]; then
  mode="ランナーの PHP"
  printf '#!/usr/bin/env bash\nexec php "$@"\n' > "$RUNNER_TEMP/bin/php-target"
else
  mode="Docker の php:$version-cli"
  docker pull --quiet "php:$version-cli" >/dev/null
  cat > "$RUNNER_TEMP/bin/php-target" <<SH
#!/usr/bin/env bash
exec docker run --rm -i -u "\$(id -u):\$(id -g)" -e HOME=/tmp -e COMPOSER_HOME=/tmp/composer \\
  -v "$GITHUB_WORKSPACE:$GITHUB_WORKSPACE" -v "$composer_bin:$composer_bin:ro" -w "\$PWD" \\
  "php:$version-cli" php "\$@"
SH
fi
printf '#!/usr/bin/env bash\nexec php-target %q --no-plugins "$@"\n' "$composer_bin" > "$RUNNER_TEMP/bin/composer-target"
chmod +x "$RUNNER_TEMP/bin/"*
echo "$RUNNER_TEMP/bin" >> "$GITHUB_PATH"
echo "version=$version" >> "$GITHUB_OUTPUT"
echo "PHP $version（$source から。実行: $mode）" | tee "$LOGS/php-version.txt"
