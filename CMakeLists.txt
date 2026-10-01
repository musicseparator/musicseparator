cmake_minimum_required(VERSION 3.24)
project(MusicSeparator VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ---------------------------------------------------------------------------
# Dependencies
#  - Qt 6 and FFmpeg: provided by vcpkg manifest mode (see vcpkg.json)
#  - ONNX Runtime: vendored under third_party/onnxruntime (official
#    Microsoft.ML.OnnxRuntime.DirectML package: DirectML + CPU providers)
# ---------------------------------------------------------------------------
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Qt6 REQUIRED COMPONENTS Widgets Multimedia Network Concurrent)
find_package(ONNXRuntime REQUIRED)

# vcpkg's FFmpeg package does not provide targets such as FFMPEG::avcodec.
# Use the pkg-config metadata installed with FFmpeg instead.
find_package(PkgConfig REQUIRED)
pkg_check_modules(AVCODEC REQUIRED IMPORTED_TARGET libavcodec)
pkg_check_modules(AVFORMAT REQUIRED IMPORTED_TARGET libavformat)
pkg_check_modules(AVUTIL REQUIRED IMPORTED_TARGET libavutil)
pkg_check_modules(SWRESAMPLE REQUIRED IMPORTED_TARGET libswresample)

# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------
set(MS_SOURCES
    src/main.cpp
    resources/app.rc
    src/MainWindow.cpp
    src/MainWindow.h
    src/AppContext.h

    src/common/ErrorCodes.cpp
    src/common/ErrorCodes.h
    src/common/ErrorDialog.cpp
    src/common/ErrorDialog.h

    src/settings/Settings.cpp
    src/settings/Settings.h
    src/settings/SettingsDialog.cpp
    src/settings/SettingsDialog.h

    src/audio/AudioBuffer.h
    src/audio/AudioDecoder.cpp
    src/audio/AudioDecoder.h
    src/audio/AudioEngine.cpp
    src/audio/AudioEngine.h
    src/audio/MixerDevice.cpp
    src/audio/MixerDevice.h
    src/audio/Waveform.cpp
    src/audio/Waveform.h

    src/separation/SeparationTypes.h
    src/separation/IModelRunner.h
    src/separation/ChunkedInference.h
    src/separation/OnnxModel.cpp
    src/separation/OnnxModel.h
    src/separation/ModelResolver.cpp
    src/separation/ModelResolver.h
    src/separation/StemSeparator.cpp
    src/separation/StemSeparator.h
    src/separation/SeparationWorker.cpp
    src/separation/SeparationWorker.h

    src/midi/MidiExportDialog.cpp
    src/midi/MidiExportDialog.h

    src/export/AudioExporter.cpp
    src/export/AudioExporter.h
    src/export/ExportFormat.h

    src/youtube/YtDlpRunner.cpp
    src/youtube/YtDlpRunner.h
    src/youtube/YouTubeImporter.cpp
    src/youtube/YouTubeImporter.h

    src/ui/Theme.cpp
    src/ui/Theme.h
    src/ui/StudioWindow.cpp
    src/ui/StudioWindow.h
    src/ui/SplashScreen.cpp
    src/ui/SplashScreen.h
    src/ui/AppearanceDialog.cpp
    src/ui/AppearanceDialog.h
    src/ui/WaveformWidget.cpp
    src/ui/WaveformWidget.h
    src/ui/TransportBar.cpp
    src/ui/TransportBar.h
    src/ui/ImportDropZone.cpp
    src/ui/ImportDropZone.h
    src/ui/TrackCard.cpp
    src/ui/TrackCard.h
    src/ui/MixConsoleWidget.cpp
    src/ui/MixConsoleWidget.h
    src/ui/ProcessingOverlay.cpp
    src/ui/ProcessingOverlay.h
)

add_executable(MusicSeparator WIN32 ${MS_SOURCES})

target_include_directories(MusicSeparator PRIVATE src)

target_link_libraries(MusicSeparator PRIVATE
    Qt6::Widgets
    Qt6::Multimedia
    Qt6::Network
    Qt6::Concurrent
    ONNXRUNTIME::ONNXRUNTIME
    PkgConfig::AVCODEC
    PkgConfig::AVFORMAT
    PkgConfig::AVUTIL
    PkgConfig::SWRESAMPLE
)

# Qt resource file (theme + icons)
target_sources(MusicSeparator PRIVATE resources/resources.qrc)

set_target_properties(MusicSeparator PROPERTIES
    AUTOMOC ON
    AUTORCC ON
    AUTOUIC ON
    WIN32_EXECUTABLE TRUE
    OUTPUT_NAME "MusicSeparator"
)

include(cmake/Warnings.cmake)
ms_enable_warnings(MusicSeparator)

# ---------------------------------------------------------------------------
# Deployment: windeployqt + runtime assets next to the exe
# ---------------------------------------------------------------------------
include(cmake/DeployHelpers.cmake)
ms_deploy(MusicSeparator)
add_custom_command(TARGET MusicSeparator POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/midi" "$<TARGET_FILE_DIR:MusicSeparator>/midi"
    COMMENT "Deploying local MIDI transcription worker" VERBATIM)

# Optional regression sources may be absent from UI-only exports.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/MixerDeviceTests.cpp")
    add_executable(MixerDeviceTests EXCLUDE_FROM_ALL
        tests/MixerDeviceTests.cpp src/audio/MixerDevice.cpp src/audio/MixerDevice.h)
    set_target_properties(MixerDeviceTests PROPERTIES AUTOMOC ON)
    target_include_directories(MixerDeviceTests PRIVATE src)
    target_link_libraries(MixerDeviceTests PRIVATE Qt6::Core)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/SeparationMathTests.cpp")
    add_executable(SeparationMathTests EXCLUDE_FROM_ALL tests/SeparationMathTests.cpp)
    target_include_directories(SeparationMathTests PRIVATE src)
endif()

# Optional subprocess/atomic-export regression executable.
add_executable(MidiWorkerTests EXCLUDE_FROM_ALL tests/MidiWorkerTests.cpp
    src/midi/MidiExportDialog.cpp src/midi/MidiExportDialog.h)
set_target_properties(MidiWorkerTests PROPERTIES AUTOMOC ON)
target_include_directories(MidiWorkerTests PRIVATE src)
target_link_libraries(MidiWorkerTests PRIVATE Qt6::Widgets)

