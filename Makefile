#!/usr/bin/make -f
# -*- mode:makefile -*-

help:
	echo "make help       	- Imprime esta ayuda"
	echo "make push       	- Sube cambios al repositorio"
	echo "make pull	      	- Actualiza el repositorio"
	echo "make run_serial 	- Actualiza, copia y ejecuta el codigo mavlink_serial.c"
	echo "make credentials	- Guarda las credenciales de git"

push: clean delete_executables
	git add * -f
	git commit -m "Commit desde Makefile"
	git push origin master

pull: delete_executables
	git pull

credentials:
	git config --global credential.helper 'cache --timeout 3600'

clean:
	$(RM) *~
