ifeq ($(DEBUG),yes)
  CFLAGS=-g -O0 -m64 -fopenmp -DDEBUG
  ISPC=ispc -g -O0 --arch=x86-64 -DDEBUG
else
  CFLAGS=-O2 -m64 -fopenmp
  ISPC=ispc -O2 --arch=x86-64 --woff
endif

ISPC_OBJS4=$(addprefix objs4/, $(ISPC_SRC:.ispc=_ispc.o) $(ISPC_SRC:.ispc=_ispc_sse2.o) $(ISPC_SRC:.ispc=_ispc_sse4.o) $(ISPC_SRC:.ispc=_ispc_avx.o))
ISPC_OBJS8=$(addprefix objs8/, $(ISPC_SRC:.ispc=_ispc.o) $(ISPC_SRC:.ispc=_ispc_sse2.o) $(ISPC_SRC:.ispc=_ispc_sse4.o) $(ISPC_SRC:.ispc=_ispc_avx.o))
ISPC_HEADERS4=$(addprefix objs4/, $(ISPC_SRC:.ispc=_ispc.h))
ISPC_HEADERS8=$(addprefix objs8/, $(ISPC_SRC:.ispc=_ispc.h))
CPP_OBJS4=$(addprefix objs4/, $(CPP_SRC:.cpp=.o))
CPP_OBJS8=$(addprefix objs8/, $(CPP_SRC:.cpp=.o))
C_OBJS4=$(addprefix objs4/, $(C_SRC:.c=.o))
C_OBJS8=$(addprefix objs8/, $(C_SRC:.c=.o))
LIBS=-lm

default: dirs headers $(ISPC_HEADERS4) $(ISPC_HEADERS8) $(CPP_OBJS4) $(CPP_OBJS8) $(C_OBJS4) $(C_OBJS8) $(LIB)4.a $(LIB)8.a $(EXE)4 $(EXE)8

.PHONY: dirs clean print

print:
	@echo $(ISPC_HEADERS4)
	@echo $(CPP_OBJS4)
	@echo $(C_OBJS4)
	@echo $(ISPC_OBJS4)
	@echo $(ISPC_HEADERS8)
	@echo $(CPP_OBJS8)
	@echo $(C_OBJS8)
	@echo $(ISPC_OBJS8)

dirs:
	/bin/mkdir -p objs4/
	/bin/mkdir -p objs8/

headers:
	python headers.py

del:
	find ./ -iname "*.dump" -exec rm '{}' ';'

clean:
	/bin/rm -rf objs* *~ $(EXE)4 $(EXE)8 *.dSYM $(LIB)4.a $(LIB)8.a dynlb4.h dynlb8.h
	find ./ -iname "*.dump" -exec rm '{}' ';'

$(LIB)4.a: $(CPP_OBJS4) $(C_OBJS4) $(ISPC_OBJS4)
	ar rcv $@ $(CPP_OBJS4) $(C_OBJS4) $(ISPC_OBJS4)
	ranlib $@ 

$(LIB)8.a: $(CPP_OBJS8) $(C_OBJS8) $(ISPC_OBJS8)
	ar rcv $@ $(CPP_OBJS8) $(C_OBJS8) $(ISPC_OBJS8)
	ranlib $@ 

$(EXE)4: objs4/test.o $(CPP_OBJS4) $(C_OBJS4) $(ISPC_OBJS4)
	$(MPICXX) $(CFLAGS) -fopenmp -o $@ $^ $(LIBS)

$(EXE)8: objs8/test.o $(CPP_OBJS8) $(C_OBJS8) $(ISPC_OBJS8)
	$(MPICXX) $(CFLAGS) -fopenmp -o $@ $^ $(LIBS)

objs4/%_ispc.h objs4/%_ispc.o objs4/%_ispc_sse2.o objs4/%_ispc_sse4.o objs4/%_ispc_avx.o: %.ispc
	$(ISPC) -DREAL=4 --target=$(ISPC_TARGETS) $< -o objs4/$*_ispc.o -h objs4/$*_ispc.h

objs8/%_ispc.h objs8/%_ispc.o objs8/%_ispc_sse2.o objs8/%_ispc_sse4.o objs8/%_ispc_avx.o: %.ispc
	$(ISPC) -DREAL=8 --target=$(ISPC_TARGETS) $< -o objs8/$*_ispc.o -h objs8/$*_ispc.h

objs4/tasksys.o: tasksys.cpp
	$(MPICXX) $(CFLAGS) -D ISPC_USE_OMP $< -c -o $@

objs8/tasksys.o: tasksys.cpp
	$(MPICXX) $(CFLAGS) -D ISPC_USE_OMP $< -c -o $@

objs4/%.o: %.cpp $(ISPC_HEADERS4)
	$(MPICXX) -DREAL=4 -Iobjs4 $(CFLAGS) $< -c -o $@

objs8/%.o: %.cpp $(ISPC_HEADERS8)
	$(MPICXX) -DREAL=8 -Iobjs8 $(CFLAGS) $< -c -o $@

objs4/%.o: %.c $(ISPC_HEADERS4)
	$(MPICC) -DREAL=4 -Iobjs4 $(CFLAGS) $< -c -o $@

objs8/%.o: %.c $(ISPC_HEADERS8)
	$(MPICC) -DREAL=8 -Iobjs8 $(CFLAGS) $< -c -o $@
