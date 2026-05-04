#!/usr/bin/env bash
# Aplica defaults Xcode otimizados para Macs de 8 GB de RAM.
# Voltar ao normal: scripts/restore-xcode-defaults.sh
set -euo pipefail

# Limita compile concurrency (default = #cores; em 8 GB causa thrashing).
defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks      -int 2
defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentSwiftCompileTasks -int 2

# Desliga indexação automática de SPM (usa CPU + RAM ao abrir cada projeto).
defaults write com.apple.dt.Xcode IDEDisableSwiftPackageIndex -bool YES

# Desliga daemon do source-control integrado; use a CLI git diretamente.
defaults write com.apple.dt.Xcode IDESourceControlEnableSourceControl -bool NO

# Reduz overhead visual do preview canvas.
defaults write com.apple.dt.Xcode IDEPreviewsEnableScreenshotChrome -bool NO

# Mac Catalyst com idiom iPad (mais leve que macOS native).
defaults write com.apple.dt.Xcode DVTDisableMacCatalystForceMacIdiom -bool YES

echo "Xcode RAM-friendly defaults applied."
echo "Reabra o Xcode (cmd-Q + reopen) para tudo entrar em vigor."
