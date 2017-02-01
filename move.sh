#! /bin/bash
# move.sh -help para mostrar todos las opciones disponibles
#Realizado por Javier Parra Patiño

function default() {
	directories=`find -maxdepth 1 -type d | tail -n +2 | grep -v VistaPreliminar | grep -v '^\.\/\.[a-zA-Z0-9]'` #Elimina de la busqueda directorios ocultos (ej.: .git)
	`mkdir -p VistaPreliminar`
	`echo "This is the Github repository for project Eyes of Things. Please contact us." > README.md`

	n_directories=`echo "$directories" | wc -l `
	element=1

	while [ $element -le $n_directories ]
	do
		aux=`echo "$directories" | head -n $element | tail -n 1`
		rsync -r "$aux" VistaPreliminar
		element=$(( $element + 1 ))
	done

	`find VistaPreliminar/ -type d -empty -exec cp README.md {}/README.md \;`
	`rm README.md`
}

function upRepo() {
	echo "Clonando el repositorio..."
	git clone $repositorio

	echo "Añadiendo el directorio..."

	github=`ls -dt */ | head -n 1`
	directories=`find VistaPreliminar/ -maxdepth 1 -type d | tail -n +2`

	n_directories=`echo "$directories" | wc -l `
	element=1

	while [ $element -le $n_directories ]
	do
		aux=`echo "$directories" | head -n $element | tail -n 1`
		rsync -r "$aux" $github
		element=$(( $element + 1 ))
	done

	cd $github
	git add * -f
	git commit -m "Commit desde move.sh -upRepo"
	git push origin master

	echo "Borrando el directorio clonado..."
	cd ..
	`ls -dt */ | head -n 1 | xargs rm -f -r`

}

function only() {
	`mkdir -p VistaPreliminar`
	`echo "This is the Github repository for project Eyes of Things. Please contact us." > README.md`
	n_dir=$@
	cadena=${n_dir:6} #6 porque son los caracteres de "-only "

	SAVEIFS=$IFS
	IFS='}' #Cada subdirectorio termina con el caracter }

	count=0
	for i in $cadena
	do
		if [[ count -eq 1 && -d ${i:1} ]]; then
			mkdir -p VistaPreliminar/${i:1}
			rsync -r ${i:1} VistaPreliminar/${i:1}
		elif [ -d $i ]; then
			mkdir -p VistaPreliminar/$i
			rsync -r $i VistaPreliminar/$i
		fi
		count=1
	done

	IFS=$SAVEIFS

	`find VistaPreliminar/ -type d -empty -exec cp README.md {}/README.md \;`
	`rm README.md`
}

function onlyRename() {
	`mkdir -p VistaPreliminar`
	`echo "This is the Github repository for project Eyes of Things. Please contact us." > README.md`

	n_dir=$@
	cadena=${n_dir:12}

	SAVEIFS=$IFS
	IFS='}'

	vector=(${cadena// / }) #Para transformar el string(cadena) a un array(vector)
	LIMITE=${#vector[@]}

	for ((x=0; x < $LIMITE; x=x+2))
	do
		if [[ $x -gt 0 && -d ${vector[$x]:1} ]]; then
			mkdir -p VistaPreliminar/${vector[$x+1]:1}
			rsync -r ${vector[$x]:1}/ VistaPreliminar/${vector[$x+1]:1}
		elif [ -d ${vector[$x]} ]; then
			mkdir -p VistaPreliminar/${vector[$x+1]:1}
			rsync -r ${vector[$x]}/ VistaPreliminar/${vector[$x+1]:1}
		fi
	done

	`find VistaPreliminar/ -type d -empty -exec cp README.md {}/README.md \;`
	`rm README.md`

	IFS=$SAVEIFS
}

function deletePreview() {
	echo "Eliminando el directorio 'VistaPreliminar'..."
	`rm -rf VistaPreliminar`
	echo "Directorio eliminado"
}

function deleteDirsRepo() {
	SAVEIFS=$IFS
	IFS='}'

	n_dir=$@
	cadena=${n_dir:15}
	vector=(${cadena// / })
	LIMITE=${#vector[@]}

	echo "Clonando el repositorio..."
	git clone ${vector[0]:1}

	github=`ls -dt */ | head -n 1`
	cd $github

	for ((x=1; x < $LIMITE; x++))
	do
		if [ -d ${vector[$x]:1} ]; then
			git rm -rf ${vector[$x]:1}
		fi
	done

	git add * -f
	git commit -m "Commit desde move.sh -deleteDirsRepo"
	git push origin master

	echo "Todos los directorios seleccionados fueron borrados de GitHub"
	cd ..
	`ls -dt */ | head -n 1 | xargs rm -rf`

	IFS=$SAVEIFS
}

function renameDirsRepo() {
	SAVEIFS=$IFS
	IFS='}'

	n_dir=$@
	cadena=${n_dir:15}
	vector=(${cadena// / })
	LIMITE=${#vector[@]}

	echo "Clonando el repositorio..."
	git clone ${vector[0]:1}

	github=`ls -dt */ | head -n 1`
	cd $github

	for ((x=1; x < $LIMITE; x=x+2))
	do
		mkdir -p ${vector[$x+1]:1}
		git mv ${vector[$x]:1}* ${vector[$x+1]:1}
	done

	git add * -f
	git commit -m "Commit desde move.sh -renameDirsRepo"
	git push origin master

	echo "Borrando el directorio clonado..."
	cd ..
	`ls -dt */ | head -n 1 | xargs rm -f -r`

	IFS=$SAVEIFS
}

echo ""
if [ $# -eq 0 ]; then #./move.sh
	echo "Copiando todas las carpetas y subcarpetas..."
	default
	echo "Todas las carpetas a subir se encuentran en el directorio 'VistaPreliminar'"

elif [[ $1 = "-upRepo" || $1 = "-uR" ]] && [ $# -gt 1 ]; then #./move.sh -upRepo https://github.com/PruebasVisilab/Destino.git}
	echo "Subiendo al repositorio seleccionado..."
	repositorio=$2
	upRepo
	deletePreview

elif [[ $1 = "-only" && $# -gt 1 ]]; then #./move.sh -only Animales/Mamiferos/Terrestres/}
	echo "Copiando recursivamente todas las carpetas seleccionadas..."
	only $@
	echo "Todas las carpetas seleccionadas para subir se encuentran en el directorio 'VistaPreliminar'"

elif [[ $1 = "-onlyRename" && $# -gt 2 ]]; then #./move.sh -onlyRename ReyLeon/Mono/} ReyLeon/Mandril/}
	echo "Renombrando los archivos seleccionados...."
	onlyRename $@
	echo "Todas las carpetas seleccionadas y renombradas se encuentran en el directorio 'VistaPreliminar'"

elif [[ $1 = "-deletePreview" || $1 = "-dp" ]]; then #./move.sh -deletePreview
	deletePreview

elif [[ $1 = "-deleteDirsRepo" && $# -gt 2 ]]; then #./move.sh -deleteDirsRepo https://github.com/PruebasVisilab/Destino.git} Animales/}
	echo "Eliminando los directorios seleccionados..."
	deleteDirsRepo $@

elif [[ $1 = "-renameDirsRepo" && $# -gt 3 ]]; then #./move.sh -renameDirsRepo https://github.com/PruebasVisilab/Destino.git} ReyLeon/Mono/} ReyLeon/Mandril/}
	echo "Renombrando los directorios seleccionados..."
	renameDirsRepo $@

elif [[ $1 = "-help" || $1 = "-h" ]]; then #./move.sh -help
	echo "./move.sh ------------------------------------------------------------------------------------> copia todos los directorios de este directorio y los copia en 'VistaPreliminar'"
	echo "./move.sh -uR, -upRepo <Web URL del directorio GitHub> ---------------------------------------> sube todas las carpetas contenidas en 'VistaPreliminar' en el directorio GitHub especificado. No sobrescribe"
	echo "./move.sh -only <Directorio a subir>/} ... ----------------------------------------------------> copia los directorios especificados y los guarda en 'VistaPreliminar'"
	echo "./move.sh -onlyRename <Nombre antiguo del directorio>/} <Nombre nuevo del directorio>/} ... ----> copia los directorios especificados renombrandolos según el nombre indicado. Guardados en 'VistaPreliminar'"
	echo "./move.sh -dp, -deletePreview ----------------------------------------------------------------> borra la carpeta 'VistaPreliminar' y todo su contenido"
	echo "./move.sh -deleteDirsRepo  <Web URL GitHub>} <Directorio a borrar>/} ... -----------------------> borra el directorio indicado del repositorio GitHub"
	echo "./move.sh -renameDirsRepo <Web URL GitHub>} <Antiguo directorio>/} <Nuevo del directorio>/} ... ... -> renombra en el repositoio GitHub los directorios indicados"
	echo "./move.sh -h, -help --------------------------------------------------------------------------> muestra esta ayuda"
	echo ""
	echo "- Tras indicar un directorio o ruta, se deberá de colocar siempre la barra y el cierre de llaves. Para URL, siempre la llave -->  directorio: /}  URL: }"
	echo "- Todas las opciones soportan multitud de directorios en la misma ejecución. Por ejemplo --> ./move.sh -only Animales/} ReyLeon/Leon/} "
	echo "- En cada ejecución del programa sólo es válido un modo de funcionamiento. Por ejemplo, no es posible --> ./move.sh -only Animales/ -upRepo https://github.com/PruebasVisilab/Destino.git"
	echo "- Para seleccionar directorios con espacios en su nombre (ej.: El Rey Leon) se deberá indicar con: \"El Rey Leon\" ó El\ Rey\ León/ "

else
	echo "Error! El comando introducido no existe o está mal escrito."
	echo "Por favor, utilice el comando -help para consultar todas las opciones disponibles"
fi

echo ""
exit 0
