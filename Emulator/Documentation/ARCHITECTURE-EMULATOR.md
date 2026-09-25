# SwitchEmu — Architektur und ehrlicher Implementierungsstand

> Kein Platzhalter wird als fertig behauptet. Jede Komponente ist unten als
> IMPLEMENTIERT (echter, getesteter Code) oder STUB/GERUEST (Schnittstelle
> ohne echte Funktion) markiert.

## Was dieses Projekt ist

Natives iOS/iPadOS-App-Geruest (SwiftUI + Swift 6 + Metal) mit modularer
Emulator-Architektur. Es laeuft, startet Demo-Binaerdateien (`.bin`, selbst
erstellt, max. 8 MiB) in einem bounds-geprueften Adressraum und rendert ein
Metal-Testbild. **Es kann keine Switch-Spiele ausfuehren.**

## Rechtliche Leitplanken (nicht verhandelbar)

- Keine Nintendo-Dateien im Repo, keine Keys, keine Firmware, keine Spiele.
- Kein Download geschuetzter Inhalte, keine Lomax-DRM-Umgehung, keine
  Entschluesselung. Der Import akzeptiert nur rohe `.bin`-Demos.
- Keine Telemetrie, keine Netzwerkfunktionen im Emulator.

## Modulstatus

| Modul | Datei(en) | Status |
|---|---|---|
| App-Lifecycle, State | `App/` | IMPLEMENTIERT |
| SwiftUI: Library/Emu/Settings/Logs | `UI/` | IMPLEMENTIERT |
| Touch-Controls (Layouts, Skalierung, Haptik) | `UI/TouchControlsView.swift`, `Input/TouchController.swift` | IMPLEMENTIERT |
| Scheduler (start/pause/ticks) | `Emulator/Scheduler.swift` | IMPLEMENTIERT + Tests |
| Interrupts (Prioritaets-Queue) | `Emulator/InterruptController.swift` | IMPLEMENTIERT + Tests |
| Core-Orchestrator | `Emulator/EmulatorCore.swift` | IMPLEMENTIERT (Demo-Scope) |
| Virtueller Adressraum (Regions, Guards) | `Memory/VirtualMemory.swift` | IMPLEMENTIERT + Tests |
| Demo-ISA-Interpreter (6 Opcodes, kein ARMv8) | `CPU/Arm64Interpreter.swift` | IMPLEMENTIERT + Tests |
| JIT-Policy (iOS verbietet RWX-JIT) | `CPU/JitPolicy.swift` | IMPLEMENTIERT (immer Interpreter) |
| GPU-Interface + NullGpu | `GPU/GpuAbstraction.swift` | IMPLEMENTIERT |
| Frame-Pacing-Logik | `GPU/FramePacer.swift` | IMPLEMENTIERT + Tests |
| Metal-Renderer (Testbild, Triple-Buffer, VSync) | `Metal/MetalRenderer.swift`, `Shaders.metal` | GERUEST (kein Spiel-Rendering) |
| Texture-Cache | `Metal/TextureCache.swift` | IMPLEMENTIERT (ungenutzte Kapazitaet) |
| Shader-Cache-Store | `ShaderCache/` | IMPLEMENTIERT |
| Audio (RingBuffer + AVAudioEngine) | `Audio/` | IMPLEMENTIERT, RingBuffer + Tests |
| Controller (GC-Framework, Profile) | `Input/GameControllerBridge.swift` | TEILWEISE (Rumble nicht verdrahtet) |
| Sandbox-Dateisystem (Picker, Bookmarks) | `Filesystem/SandboxFS.swift` | IMPLEMENTIERT |
| Saves (Profile, Backup/Restore) | `SaveSystem/` | IMPLEMENTIERT |
| Performance-Monitor (FPS, Frame-Time, RAM) | `Performance/` | IMPLEMENTIERT (CPU/GPU-Last: nicht verfuegbar, wird so angezeigt) |
| Logging (Level, Export) | `Logging/` | IMPLEMENTIERT |
| Unit-Tests | `Tests/CoreTests.swift` | IMPLEMENTIERT (10 Tests) |

## Bekannte Einschraenkungen

1. Kein ARMv8-/Switch-CPU: nur Demo-ISA. Echte Switch-Ausfuehrung fehlt
   vollstaendig und ist ein Mehrjahresvorhaben (Horizon-Syscalls, dynarec
   unter iOS-JIT-Restriktionen).
2. Kein Maxwell-GPU/NVN: Metal zeigt ein Testmuster, keine Spielegrafik.
3. Kein Audio-Input aus Spielen: Engine spielt nur eingespeiste PCM-Bloecke.
4. CPU-/GPU-Lastauswertung: ohne private APIs nicht messbar, daher bewusst
   als „nicht verfuegbar" statt gefaelscht.
5. IPA ist unsigniert ohne Apple-Secrets; Installation erst nach Re-Sign.

## Naechste Schritte (falls gewuenscht)

- ARMv8-A-Interpreter (offene ISA-Doku) ohne proprietäre Anteile.
- METAL-Backend an echte Kommando-Puffer koppeln, sobald CPU liefert.
- Touch-Layout-Editor (Drag-to-Position im UI statt Presets).
