#!make

run:
	craftos --id 2828 --exec "shell.run('clear') shell.run('youcube')" --mount-ro /=./client

illuaminate-lint:
	illuaminate lint

illuaminate-doc-gen:
	illuaminate doc-gen

cleanup:
	rm doc -Rv || true

install-illuaminate-linux:
	wget https://squiddev.cc/illuaminate/bin/latest/illuaminate-linux-x86_64 -O /usr/bin/illuaminate
	chmod +x /usr/bin/illuaminate
