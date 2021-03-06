.SHELLFLAGS := -eu -o pipefail -c
SHELL := bash
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: build
build: target/release/libpymemprofile_api.a
	pip install -e .
	rm -rf build/
	python setup.py build_ext --inplace

target/release/libpymemprofile_api.a: Cargo.lock memapi/Cargo.toml memapi/src/*.rs
	cargo build --release

venv:
	python3 -m venv venv/

.PHONY: test
test:
	make test-rust
	make test-python

.PHONY: test-rust
test-rust:
	env RUST_BACKTRACE=1 cargo test

.PHONY: test-python
test-python: build
	cythonize -3 -i python-benchmarks/pymalloc.pyx
	c++ -shared python-benchmarks/cpp.cpp -o python-benchmarks/cpp.so
	cd python-benchmarks && python -m numpy.f2py -c fortran.f90 -m fortran
	env RUST_BACKTRACE=1 py.test

.PHONY: docker-image
docker-image:
	docker build -t manylinux-rust -f wheels/Dockerfile.build .

.PHONY: wheel
wheel:
	python setup.py bdist_wheel

.PHONY: manylinux-wheel
manylinux-wheel:
	docker run -u $(shell id -u):$(shell id -g) -v $(PWD):/src quay.io/pypa/manylinux2010_x86_64:latest /src/wheels/build-wheels.sh

.PHONY: clean
clean:
	rm -f filprofiler/fil-python
	rm -rf target
	rm -rf filprofiler/*.so
	rm -rf filprofiler/*.dylib
	python setup.py clean

.PHONY: licenses
licenses:
	cd memapi && cargo lichking check
	cd memapi && cargo lichking bundle --file ../filprofiler/licenses.txt || true
	cat extra-licenses/APSL.txt >> filprofiler/licenses.txt
