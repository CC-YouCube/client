#!make

run-server:
	python server/youcube.py

run-client:
	craftos --id 2828 --exec "shell.run('youcube')" --mount-ro /=./client

docker-build:
	docker build -t youcube:1.0.0 -t youcube:latest server/.

illuaminate-lint:
	illuaminate lint

pylint:
	pylint server/*.py

pyspelling:
	pyspelling

illuaminate-doc-gen:
	illuaminate doc-gen

cleanup:
	rm doc server/data -Rv

install-illuaminate-linux:
	wget https://squiddev.cc/illuaminate/linux-x86-64/illuaminate -P /usr/bin
	chmod +x /usr/bin/illuaminate

install-pylint:
	pip install pylint

install-pyspelling:
	pip install pyspelling
