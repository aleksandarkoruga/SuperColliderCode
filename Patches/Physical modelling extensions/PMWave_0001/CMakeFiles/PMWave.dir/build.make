# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.14

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.14.3/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.14.3/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/aleksandar/Projects/SuperCollider/PMWave_0001

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/aleksandar/Projects/SuperCollider/PMWave_0001

# Include any dependencies generated for this target.
include CMakeFiles/PMWave.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/PMWave.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/PMWave.dir/flags.make

CMakeFiles/PMWave.dir/PMWave.cpp.o: CMakeFiles/PMWave.dir/flags.make
CMakeFiles/PMWave.dir/PMWave.cpp.o: PMWave.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/aleksandar/Projects/SuperCollider/PMWave_0001/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/PMWave.dir/PMWave.cpp.o"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/PMWave.dir/PMWave.cpp.o -c /Users/aleksandar/Projects/SuperCollider/PMWave_0001/PMWave.cpp

CMakeFiles/PMWave.dir/PMWave.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/PMWave.dir/PMWave.cpp.i"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/aleksandar/Projects/SuperCollider/PMWave_0001/PMWave.cpp > CMakeFiles/PMWave.dir/PMWave.cpp.i

CMakeFiles/PMWave.dir/PMWave.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/PMWave.dir/PMWave.cpp.s"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/aleksandar/Projects/SuperCollider/PMWave_0001/PMWave.cpp -o CMakeFiles/PMWave.dir/PMWave.cpp.s

# Object files for target PMWave
PMWave_OBJECTS = \
"CMakeFiles/PMWave.dir/PMWave.cpp.o"

# External object files for target PMWave
PMWave_EXTERNAL_OBJECTS =

PMWave.scx: CMakeFiles/PMWave.dir/PMWave.cpp.o
PMWave.scx: CMakeFiles/PMWave.dir/build.make
PMWave.scx: CMakeFiles/PMWave.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/Users/aleksandar/Projects/SuperCollider/PMWave_0001/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX shared module PMWave.scx"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/PMWave.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/PMWave.dir/build: PMWave.scx

.PHONY : CMakeFiles/PMWave.dir/build

CMakeFiles/PMWave.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/PMWave.dir/cmake_clean.cmake
.PHONY : CMakeFiles/PMWave.dir/clean

CMakeFiles/PMWave.dir/depend:
	cd /Users/aleksandar/Projects/SuperCollider/PMWave_0001 && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/aleksandar/Projects/SuperCollider/PMWave_0001 /Users/aleksandar/Projects/SuperCollider/PMWave_0001 /Users/aleksandar/Projects/SuperCollider/PMWave_0001 /Users/aleksandar/Projects/SuperCollider/PMWave_0001 /Users/aleksandar/Projects/SuperCollider/PMWave_0001/CMakeFiles/PMWave.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/PMWave.dir/depend
