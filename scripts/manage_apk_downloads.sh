#!/usr/bin/env bash
# Prune old APKs from Flutter build output folders (keep newest only)
# and copy new APKs to /var/www/html/download (accumulate history there).

set -euo pipefail

FLUTTER_APK_DIR="/var/www/html/flutter/quikdawa/build/app/outputs/flutter-apk"
RELEASE_APK_DIR="/var/www/html/flutter/quikdawa/build/app/outputs/apk/release"
DOWNLOAD_DIR="/var/www/html/download"
LOG_TAG="[quikdawa-apk-sync]"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') ${LOG_TAG} $*"
}

prune_keep_newest_apk() {
  local dir="$1"
  local label="$2"

  if [[ ! -d "$dir" ]]; then
    log "Skip ${label}: directory not found (${dir})"
    return 0
  fi

  mapfile -t apk_files < <(find "$dir" -maxdepth 1 -type f -name '*.apk' -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2-)

  if [[ ${#apk_files[@]} -eq 0 ]]; then
    log "No APK files in ${label}"
    return 0
  fi

  local newest="${apk_files[0]}"
  log "Newest in ${label}: $(basename "$newest")"

  local file
  for file in "${apk_files[@]:1}"; do
    log "Removing old APK from ${label}: $(basename "$file")"
    rm -f "$file"
  done
}

copy_newest_to_download() {
  local dir="$1"
  local label="$2"

  if [[ ! -d "$dir" ]]; then
    return 0
  fi

  local newest
  newest="$(find "$dir" -maxdepth 1 -type f -name '*.apk' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"

  if [[ -z "$newest" ]]; then
    return 0
  fi

  local filename
  filename="$(basename "$newest")"
  local dest="${DOWNLOAD_DIR}/${filename}"

  mkdir -p "$DOWNLOAD_DIR"

  if [[ -f "$dest" ]]; then
    log "Already in download (${filename}), skipping copy from ${label}"
    return 0
  fi

  log "Copying to download from ${label}: ${filename}"
  cp -p "$newest" "$dest"
}

main() {
  # Copy any new APKs to download before pruning build folders.
  copy_newest_to_download "$RELEASE_APK_DIR" "release"
  copy_newest_to_download "$FLUTTER_APK_DIR" "flutter-apk"

  # Keep only the newest APK in each build output folder.
  prune_keep_newest_apk "$RELEASE_APK_DIR" "release"
  prune_keep_newest_apk "$FLUTTER_APK_DIR" "flutter-apk"

  log "Done"
}

main "$@"
