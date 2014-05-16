# Make MTL-SDCA

SHELL = /bin/bash

ARCH ?= glnxa64
MATLAB_PATH ?= $(shell matlab -e | awk '/MATLAB=/ {print substr($$1,8)}')
INTEL_MKL_PATH = /opt/intel

SRC_DIR := src
OBJ_DIR := obj
MEX_DIR := mex

# Check if MATLAB exists
ifeq ($(wildcard $(MATLAB_PATH)),)
$(error MATLAB not found.)
endif
MEX ?= $(MATLAB_PATH)/bin/mex

# MATLAB 8.1 (R2013a) requires gcc-4.4
CC = gcc
CXX = g++
ifneq ($(findstring 8.1,$(MATLAB_PATH)),)
CC = gcc-4.4
CXX = g++-4.4
endif

# Check if Intel MKL exists and reset the path if it doesn't
ifeq ($(wildcard $(INTEL_MKL_PATH)/mkl/lib),)
INTEL_MKL_PATH =
endif

STD_CXXFLAGS = $(CXXFLAGS)
STD_CXXFLAGS += -std=c++0x
STD_CXXFLAGS += -Wall -Wextra -Werror -Wconversion -pedantic
STD_CXXFLAGS += -Wno-unused-function -Wno-long-long -Wno-variadic-macros
STD_CXXFLAGS += $(if $(DEBUG), -DDEBUG -O0 -g, -DNDEBUG -O3)
STD_CXXFLAGS += $(if $(PROFILE), -g)
STD_CXXFLAGS += -I$(SRC_DIR)
STD_CXXFLAGS += -DVERBOSE

STD_LDFLAGS = $(LDFLAGS)
OBJ_CXXFLAGS += -c

ifeq ($(ARCH),glnxa64)
STD_CXXFLAGS += -D_GNU_SOURCE -fno-stack-protector
STD_LDFLAGS += -L$(OBJ_DIR) -L$(MEX_DIR)
STD_LDFLAGS += -Wl,--rpath,\$$ORIGIN/ -Wl,--as-needed -lpthread -lm
endif

# BLAS/LAPACK flags
ifeq ($(INTEL_MKL_PATH),)
# MATLAB BLAS
$(info MATLAB BLAS)
STD_CXXFLAGS += -DBLAS_MATLAB
BLAS_LIB = -lmwblas -lmwlapack
else
# Intel MKL BLAS
$(info Intel MKL BLAS)
STD_CXXFLAGS += -DBLAS_INTEL_MKL -DMKL_ILP64 -m64 \
	-I$(INTEL_MKL_PATH)/mkl/include
BLAS_LIB = -Wl,--start-group \
	$(INTEL_MKL_PATH)/mkl/lib/intel64/libmkl_intel_ilp64.a \
	$(INTEL_MKL_PATH)/mkl/lib/intel64/libmkl_core.a \
	$(INTEL_MKL_PATH)/mkl/lib/intel64/libmkl_intel_thread.a \
	-Wl,--end-group -liomp5 -ldl
endif

STD_CXXFLAGS += -I$(MATLAB_PATH)/extern/include
MEXFLAGS += -$(ARCH) CC='$(CC)' CXX='$(CXX)'
MEXFLAGS += CFLAGS='$$CFLAGS $(STD_CXXFLAGS)'
MEXFLAGS += CXXFLAGS='$$CXXFLAGS $(STD_CXXFLAGS)'

ifeq ($(ARCH),glnxa64)
MEX_SUFFIX := mexa64
MEXFLAGS += -largeArrayDims -DMATLAB_MEX_FILE $(if $(DEBUG), -g)
MEX_LDFLAGS += CXXLIBS='$$CXXLIBS $(STD_LDFLAGS) $(BLAS_LIB)'
endif

mex_src := $(shell find $(SRC_DIR)/mex -name "*.cc" -printf '%f\n')
mex_tgt := $(addprefix $(MEX_DIR)/,$(mex_src:.cc=.$(MEX_SUFFIX)))
obj_src := $(shell find $(SRC_DIR) \
	-name "*.cc" ! -path "$(SRC_DIR)/mex/*.cc" -printf '%p\n')
obj_tgt := $(patsubst $(SRC_DIR)/%,$(OBJ_DIR)/%,$(obj_src:.cc=.o))

.PHONY: all clean LIOMP5

all: $(obj_tgt) $(mex_tgt)

$(MEX_DIR)/%.$(MEX_SUFFIX) : $(SRC_DIR)/mex/%.cc $(obj_tgt) $(MEX_DIR) LIOMP5
	$(MEX) $(MEXFLAGS) $< $(MEX_LDFLAGS) \
	-output $@ $(obj_tgt)

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.cc $(SRC_DIR)/%.h $(OBJ_DIR)
	$(CC) $(STD_CXXFLAGS) $(OBJ_CXXFLAGS) $< $(STD_LDFLAGS) -o $@

$(OBJ_DIR) :
	mkdir -p $(dir $(obj_tgt))

$(MEX_DIR) :
	mkdir -p $(MEX_DIR)

LIOMP5:
ifneq ($(INTEL_MKL_PATH),)
	cp $(INTEL_MKL_PATH)/lib/intel64/libiomp5.so $(MEX_DIR)
endif

clean:
	rm -rf $(OBJ_DIR) $(MEX_DIR)
