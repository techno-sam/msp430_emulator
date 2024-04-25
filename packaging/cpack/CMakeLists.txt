cmake_minimum_required(VERSION 3.10)
project(msp430_emulator)

# Set CPack variables
set(CPACK_PACKAGE_NAME "msp430_emulator")
set(CPACK_PACKAGE_VENDOR "techno-sam")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "techno-sam")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "An emulator and assembler for the MSP430 chip")
set(CPACK_PACKAGE_VERSION "1.4.0") # TODO: command line config?
set(CPACK_GENERATOR "NSIS64")  # You can specify the desired generator (e.g., NSIS, WIX, ZIP, etc.)
set(CMAKE_GENERATOR_PLATFORM 64)
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}\\\\..\\\\..\\\\LICENSE")
set(CPACK_INSTALL_PREFIX "./")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "msp430_emulator")

# Ensure consistent install directory
set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")

get_filename_component(COMMON_PREFIX ..\\..\\build\\windows\\x64\\runner\\Release REALPATH)

# read install manifest
file(STRINGS ..\\..\\build\\windows\\x64\\install_manifest.txt CPACK_FILES)

# Add files specified by manifest to CPack
foreach(file ${CPACK_FILES})
    # Strip the common prefix from the file path
    string(REPLACE "${COMMON_PREFIX}" "" stripped_file_path "${file}")

    # Get the directory part of the file path
    get_filename_component(dest_dir "${stripped_file_path}" DIRECTORY)

    message("Installing file: ${file} to reside in the path: ${CPACK_INSTALL_PREFIX}/${dest_dir}")

    install(FILES "${file}" DESTINATION "${CPACK_INSTALL_PREFIX}/${dest_dir}")
endforeach()
# Add the 'root' executable
install(FILES "..\\\\..\\\\build\\\\windows\\\\x64\\\\runner\\\\Release\\\\msp430_emulator.exe" DESTINATION "${CPACK_INSTALL_PREFIX}/")

# Create Start Menu shortcut
set(CPACK_NSIS_CREATE_ICONS_EXTRA "
    CreateShortCut '$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\MSP430 Emulator.lnk' '$INSTDIR\\\\msp430_emulator.exe'
")

# Yay backslashes (NSIS seems to need at least one set)
# get_filename_component
set(ICON_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..\\\\..\\\\windows\\\\runner\\\\resources\\\\app_icon.ico")# REALPATH)

set(CPACK_NSIS_MUI_ICON "${ICON_PATH}")
set(CPACK_NSIS_MUI_UNIICON "${ICON_PATH}")
set(CPACK_NSIS_UNINSTALL_NAME "Uninstall MSP430 Emulator")
set(CPACK_NSIS_DISPLAY_NAME "MSP430 Emulator")
set(CPACK_NSIS_PACKAGE_NAME "MSP430 Emulator")
set(CPACK_NSIS_URL_INFO_ABOUT "https://github.com/techno-sam/msp430_emulator")
set(CPACK_NSIS_INSTALLED_ICON_NAME "msp430_emulator.exe")
#set(CPACK_NSIS_INSTALLED_ICON_NAME "$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\MSP430 Emulator.lnk")

# Explicitly delete start menu shortcut during uninstall
set(CPACK_NSIS_DELETE_ICONS_EXTRA "
    Delete '$SMPROGRAMS\\\\$MUI_TEMP\\\\MSP430 Emulator.lnk'
")

include(CPack)
