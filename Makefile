#!make

run-server:
	python server/youcube

run-client:
	craftos --id 2828 --exec "shell.run('clear') shell.run('youcube')" --mount-ro /=./client

docker-build:
	docker build -t youcube:latest server/.

illuaminate-lint:
	illuaminate lint

pylint:
	pylint server/youcube/*.py

pyspelling:
	pyspelling

illuaminate-doc-gen:
	illuaminate doc-gen

cleanup:
	rm doc server/data server/__pycache__ -Rv || true

install-illuaminate-linux:
	wget https://squiddev.cc/illuaminate/bin/latest/illuaminate-linux-x86_64 -O /usr/bin/illuaminate
	chmod +x /usr/bin/illuaminate

install-pylint:
	pip install pylint

install-pyspelling:
	pip install pyspelling
