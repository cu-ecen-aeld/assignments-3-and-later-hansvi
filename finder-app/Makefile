CC=$(CROSS_COMPILE)gcc
CCFLAGS=-g

all: writer

writer: writer.c
	@echo "Building"
	$(CC)  -o $@ $^ $(CCFLAGS)

clean:
	@echo "Removing output files"
	rm writer
