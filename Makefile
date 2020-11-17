.PHONY: install uninstall

VENV=. ./venv/bin/activate

install:
	python -m venv venv
	$(VENV) && \
	pip install pip --upgrade && \
	pip install -r requirements.txt && \
	python setup.py develop

uninstall:
	rm -rf venv
