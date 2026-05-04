#!/usr/bin/env bash
# Reverte os defaults RAM-friendly aplicados em scripts/optimize-xcode-ram.sh
# Use isto se você voltar pra um Mac com mais RAM e quiser performance máxima.
set -euo pipefail

defaults delete com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks       || true
defaults delete com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentSwiftCompileTasks  || true
defaults delete com.apple.dt.Xcode IDEDisableSwiftPackageIndex                              || true
defaults delete com.apple.dt.Xcode IDESourceControlEnableSourceControl                      || true
defaults delete com.apple.dt.Xcode IDEPreviewsEnableScreenshotChrome                        || true
defaults delete com.apple.dt.Xcode DVTDisableMacCatalystForceMacIdiom                       || true

echo "Xcode defaults restored to factory."
