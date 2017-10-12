NPM_EXEC=PATH="`npm bin`":"$$PATH"
MIMOSA=$(NPM_EXEC) mimosa
MIMOSA_PROD_ARGS=-o --profile production

.PHONY : start startd build build-opt buildo clean pack package

start:
	@echo "[x] Building assets and starting development server..."
	$(MIMOSA) watch -s

doc:
	codo assets/javascripts/
	# --undocumented

starto:
	@echo "[x] Building assets and starting development server..."
	$(MIMOSA) watch -s -d $(MIMOSA_PROD_ARGS)

startd:
	@echo "[x] Cleaning compiled directory, building assets and starting development server.."
	$(MIMOSA) watch -sd

build:
	@echo "[x] Building assets..."
	$(MIMOSA) build

build-opt:
	@echo "[x] Building and optimizing assets..."
	$(MIMOSA) build $(MIMOSA_PROD_ARGS)

buildo:
	@echo "[x] Building and optimizing assets..."
	$(MIMOSA) build $(MIMOSA_PROD_ARGS)

clean:
	@echo "[x] Removing compiled files..."
	$(MIMOSA) clean

pack:
	@echo "[x] Building and packaging application..."
	$(MIMOSA) build -mp $(MIMOSA_PROD_ARGS)

package:
	@echo "[x] Building and packaging application..."
	$(MIMOSA) build -mp $(MIMOSA_PROD_ARGS)