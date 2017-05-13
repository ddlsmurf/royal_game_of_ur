NPM_EXEC=PATH="`npm bin`":"$$PATH"
MIMOSA=$(NPM_EXEC) mimosa

.PHONY : start startd build build-opt buildo clean pack package

start:
	@echo "[x] Building assets and starting development server..."
	$(MIMOSA) watch -s

starto:
	@echo "[x] Building assets and starting development server..."
	$(MIMOSA) watch -s -d -o

startd:
	@echo "[x] Cleaning compiled directory, building assets and starting development server.."
	$(MIMOSA) watch -sd

build:
	@echo "[x] Building assets..."
	$(MIMOSA) build

build-opt:
	@echo "[x] Building and optimizing assets..."
	$(MIMOSA) build -o

buildo:
	@echo "[x] Building and optimizing assets..."
	$(MIMOSA) build -o

clean:
	@echo "[x] Removing compiled files..."
	$(MIMOSA) clean

pack:
	@echo "[x] Building and packaging application..."
	$(MIMOSA) build -omp

package:
	@echo "[x] Building and packaging application..."
	$(MIMOSA) build -omp