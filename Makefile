# Compiler and flags
CXX = aarch64-linux-gnu-g++ # C++ compiler
CXXFLAGS = -Wall -std=c++17 -Iinclude

# Check if we are on Windows
ifeq ($(OS),Windows_NT)
    # If on Windows, set appropriate compiler (MinGW)
    CC = gcc.exe
    CXX = g++.exe
    # Set Windows-specific paths and cleanup commands
    DEL = del /q
    RMDIR = rmdir /s /q
    MKDIR = if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
    EXEC = main.exe  # Windows executable file extension
    TEST_EXEC = testExe.exe
    PATH_SEP = \\  # Windows uses backslashes
else
    # For Linux (Raspberry Pi) or other Unix-like systems
    DEL = rm -f
    RMDIR = rm -rf
    MKDIR = mkdir -p $(dir $@)
    EXEC = main  # Linux executable (no .exe)
    TEST_EXEC = testExe
    PATH_SEP = /  # Linux uses forward slashes
endif

# Directories
SRC_DIR = src
BUILD_DIR = build
TEST_DIR = tests

# Output binary name
TARGET = $(EXEC)
TEST_TARGET = $(TEST_EXEC)

# Default target:
all: $(TARGET)

# Test target:
test: TEST_FILE_CHECK $(TEST_TARGET)

### Source Files ###

# C++ Files
CXX_SRCS = $(wildcard $(SRC_DIR)/*.cpp) # Project SRC Files
TEST_SRC = $(TEST_DIR)/$(TEST_FILE) # Test "main.cpp" file to run

### Object Files ###

# C++ Object Files
CXX_OBJS = $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(CXX_SRCS))

# All Objects
OBJS = $(CXX_OBJS)

# All Test Objects (All + test.cpp - main.cpp)
TEST_OBJS = $(filter-out $(BUILD_DIR)/main.o, $(OBJS)) # $(OBJS) - main.cpp
TEST_OBJS += $(patsubst %.cpp, %.o, $(TEST_SRC)) # 			     + test.cpp

### Compiling ###

# Compiling C++ object files from src directory
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	@$(MKDIR)
	$(info Compiling $@...)
	@$(CXX) $(CXXFLAGS) -c $< -o $@

### Linking ###

# Linking Executable
$(TARGET): $(OBJS)
	$(info Linking all object files into $@...)
	$(info Linking: $(OBJS))
	@$(CXX) $(CXXFLAGS) $(OBJS) -o $@

# Linking Test Executable
$(TEST_TARGET): $(TEST_OBJS)
	$(info Linking object files without main.o, and including $(TEST_FILE) into $@...)
	$(info Linking: $(TEST_OBJS))
	@$(CXX) $(CXXFLAGS) $(TEST_OBJS) -o $@


# Check if the target is 'test'
ifeq ($(filter test,$(MAKECMDGOALS)),test)
    # These checks will only run when the 'test' target is invoked
    TEST_FILE_CHECK:
	# Check if TEST_FILE is set
	@if [ -z "$(TEST_FILE)" ]; then \
		echo "TEST_FILE is not set. Please specify the test file name with TEST_FILE=testfile.cpp"; \
		exit 1; \
	fi

	# Check if the TEST_FILE exists in TEST_DIR
	@if [ ! -f "$(TEST_DIR)/$(TEST_FILE)" ]; then \
		echo "TEST_FILE $(TEST_FILE) does not exist in $(TEST_DIR) directory"; \
		exit 1; \
	fi
endif

# Cleanup build:
clean:
ifeq ($(OS),Windows_NT)
	@if exist build $(DEL) build\* 
	@if exist build $(RMDIR) build
	@if exist $(EXEC) $(DEL) $(EXEC)
	@if exist $(TEST_EXEC) $(DEL) $(TEST_EXEC)
else
	@rm -rf $(BUILD_DIR) $(EXEC)
	@if [ -f $(TEST_TARGET) ]; then rm $(TEST_TARGET) > /dev/null 2>&1; fi
endif

.PHONY: all clean
