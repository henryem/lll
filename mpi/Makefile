# This makefile is messy.  I apologize for having no idea what I'm doing.  This
# all seems needlessly complicated in comparison to Java build tools.
# Also, the makefile is copied from a previous project and may contain
# some extraneous fluff until it is cleaned up.

# Identify what machine we're on and set up some environment-specific flags:
ifneq ($(shell uname -a | grep Ubuntu),)
  # Not actually supported.
  RAW_CC = gcc
  OSFOUND=1
endif
ifneq ($(shell uname -a | grep Darwin),)
  RAW_CC = g++-4.9 -Wall -std=c++0x
  RAW_MPCC = OMPI_MPICXX="$(RAW_CC)" mpic++
  OSFOUND=1
  RAW_NVCCFLAGS = -arch=sm_30 # My Mac supports Compute Level 3.0.  Not sure how to find this automatically.
  SUPPORTS_GPU=1
endif
ifneq ($(shell uname -a | grep hopper),)
  # Does not support GPU build.  Also, the build assumes that GNU g++ is the compiler.
  # Run ``module swap PrgEnv-pgi PrgEnv-gnu'' to switch.
  HOPPER = 1
  RAW_CC = cc -std=c++0x -Wall
  RAW_MPCC = $(RAW_CC)
  OSFOUND=1
endif
ifneq ($(shell uname -a | grep edison),)
  # Does not support GPU build.  Also, the build assumes that GNU g++ is the compiler.
  # Run ``module swap PrgEnv-pgi PrgEnv-gnu'' to switch.
  HOPPER = 1
  RAW_CC = cc -std=c++0x -Wall
  RAW_MPCC = $(RAW_CC)
  OSFOUND=1
endif
ifneq ($(shell uname -a | grep stampede),)
  # Note: Need to ``module load cuda'' first.
  STAMPEDE = 1
  RAW_CC = cc -Wall
  RAW_MPCC = $(RAW_CC)
  OSFOUND=1
  RAW_NVCCFLAGS = -arch=sm_35
  SUPPORTS_GPU=1
endif

CC = $(RAW_CC) $(FLAGS)
MPCC = $(RAW_MPCC) $(FLAGS)
ifdef DEBUG
  CFLAGS = -O0 -g -pg
  RAW_NVCCFLAGS += -DTHRUSTDEBUG
else
  CFLAGS = -O3
endif
LIBS = -lstdc++

# NVCC stuff:
NVCC = nvcc
NVCCFLAGS = $(CFLAGS) $(RAW_NVCCFLAGS)
NVCC_LIBS = -lm

OWN_LIBS = 

TARGETS = serial mpi
ifdef SUPPORTS_GPU
  TARGETS += gpu
endif
CLEAN_TARGETS = $(TARGETS)

all:	$(TARGETS)

serial: serial.o $(OWN_LIBS)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)
mpi: mpi.o $(OWN_LIBS)
	$(MPCC) $(CFLAGS) -o $@ $^ $(LIBS) $(MPILIBS)
# gpu: gpu.o common_gpu.o Stats.o
# 	$(NVCC) -o $@ $(NVCCLIBS) gpu.o common_gpu.o Stats.o

serial.o: serial.cpp $(OWN_LIBS)
	$(CC) -c $(CFLAGS) $<
mpi.o: mpi.cpp $(OWN_LIBS)
	$(MPCC) -c $(CFLAGS) $<
# gpu.o: gpu.cu common.h
# 	$(NVCC) -c $(NVCCFLAGS) gpu.cu
%.o: %.cpp %.h
	$(CC) -c $(CFLAGS) $<

clean:
	rm -f *.o $(CLEAN_TARGETS) *.stdout *.txt
