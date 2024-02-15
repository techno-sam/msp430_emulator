cmake_minimum_required(VERSION 3.10)
project(msp430_emulator)

# Set CPack variables
set(CPACK_PACKAGE_NAME "msp430_emulator")
set(CPACK_PACKAGE_VENDOR "techno-sam")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "techno-sam")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Your application description")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_GENERATOR "NSIS")  # You can specify the desired generator (e.g., NSIS, WIX, ZIP, etc.)

# Add your compiled files to be packaged
install(DIRECTORY ../../build/windows/x64/runner/Release DESTINATION .)
# install(DIRECTORY ../../build/linux/x64/release/bundle DESTINATION .)

include(CPack)
