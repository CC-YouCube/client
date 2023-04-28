#!make

ifeq ($(OS), Windows_NT)
	CRAFTOS := craftos-pc
	CLEANUP := del /s /q
else
	CRAFTOS := craftos
	CLEANUP := rm -rf
endif

run:
	$(CRAFTOS) \
		--id 2828 \
		--exec "shell.run('clear')shell.run('youcube')" \
		--mount-ro \=.\src

illuaminate-lint:
	illuaminate lint

illuaminate-doc-gen:
	illuaminate doc-gen

cleanup:
	$(CLEANUP) doc || true

install-illuaminate:
ifeq ($(OS), Windows_NT)
	if not exist C:\bin mkdir C:\bin
	curl -L -o C:\bin\illuaminate.exe \
		https://squiddev.cc/illuaminate/bin/latest/illuaminate-windows-x86_64.exe
	reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" \
		/v LongPathsEnabled | find "1" > nul || \
		echo Running enable-long-paths might be necessary if you have a long path environment!
	echo Enter password to add illuaminate to path
	runas /user:$(USERNAME) 'setx /m PATH "$(PATH);C:\bin"'
else
	wget https://squiddev.cc/illuaminate/bin/latest/illuaminate-linux-x86_64 \
		-O /usr/bin/illuaminate
	chmod +x /usr/bin/illuaminate
endif

ifeq ($(OS), Windows_NT)
enable-long-paths:
	echo You need to reboot your system after this!
	runas /user:$(USERNAME) \
		'reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" \
		/v LongPathsEnabled /t REG_DWORD /d 1 /f'
endif
