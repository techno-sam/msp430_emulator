cmake_minimum_required(VERSION 3.10)
project(YourProjectName)

# Set CPack variables
set(CPACK_PACKAGE_NAME "YourAppName")
set(CPACK_PACKAGE_VENDOR "YourCompany")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Your application description")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_GENERATOR "ZIP")  # You can specify the desired generator (e.g., NSIS, WIX, ZIP, etc.)

# Add your compiled files to be packaged
install(DIRECTORY ../../build/windows/x64/runner/Release DESTINATION .)

include(CPack)
