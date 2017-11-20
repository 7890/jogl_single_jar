#!/bin/bash

#//tb/1710

DIR="$(dirname ${BASH_SOURCE[0]})"
cd "$DIR"
DIR="`pwd`"
#echo $DIR

#==============================================================================
#SETTINGS

#this name can be freely chosen considering these rules:
#-must be a valid module name ##todo: ..
#.jar files will be using also this name
MODULE_NAME="app"
MAIN_CLASS_URI=t.EventTest
STARTUP_STRING="$MODULE_NAME"/"$MAIN_CLASS_URI"

#name of the runnable image exploded directory
#the makeself variant is using the same name + .sh
OUT_IMAGE_NAME="appImage"
#makeself app description
APP_TITLE="jlink jogl test: t.EventTest"

#==============================================================================
#JAVA
#tested with OpenJDK 10 

export JAVA_HOME=/jdk10/

export JAVA=${JAVA_HOME}/bin/java
export JAVAC=${JAVA_HOME}/bin/javac
export JAR=${JAVA_HOME}/bin/jar
export JLINK=${JAVA_HOME}/bin/jlink
export JDEPS=${JAVA_HOME}/bin/jdeps

#build scratch dir
BUILD="$DIR"/_build
#output artifacts
DIST="$DIR"/_dist

#pre-requisite: find and download jogamp-all-platforms.7z and decompress with 7zr
#then set path accordingly here
PATH_TO_JOGAMP_ALL_PLATFORMS="$DIR/jogamp-all-platforms"

JOGL_ALL_JAR="${PATH_TO_JOGAMP_ALL_PLATFORMS}/jar/jogl-all.jar"
GLUEGEN_RT_JAR="${PATH_TO_JOGAMP_ALL_PLATFORMS}/jar/gluegen-rt.jar"

CP=".:classes:${JOGL_ALL_JAR}:${GLUEGEN_RT_JAR}"

JAVA_LIBRARY_PATH="${PATH_TO_JOGAMP_ALL_PLATFORMS}/lib/linux-amd64/"
#JAVA_LIBRARY_PATH="${PATH_TO_JOGAMP_ALL_PLATFORMS}/lib/macosx-universal/"
#JAVA_LIBRARY_PATH="${PATH_TO_JOGAMP_ALL_PLATFORMS}/lib/windows-amd64/"

#    .---------- constant part!
#    vvvv vvvv-- the code from above
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_err()
{
	printf "${RED}${1}${NC}\n" >&2
}

print_task()
{
	printf "+${GREEN}${1}${NC}\n"
}

function abort()
{
	echo >&2 '
***************
*** ABORTED ***
***************
'
	print_err "there was an error."
	exit 1
}

trap 'abort' 0
set -e
# Any subsequent commands which fail will cause the shell script to exit immediately
# undo with set +e

function path_check
{
	#file / dir existence check
	if [ ! -d "${PATH_TO_JOGAMP_ALL_PLATFORMS}" ]
	then
		print_err "invalid PATH_TO_JOGAMP_ALL_PLATFORMS"
		exit 1
	fi
	if [ ! -f "${JOGL_ALL_JAR}" ]
	then
		print_err "invalid JOGL_ALL_JAR"
		exit 1
	fi
	if [ ! -f "${GLUEGEN_RT_JAR}" ]
	then
		print_err "invalid GLUEGEN_RT_JAR"
		exit 1
	fi
	if [ ! -d "${JAVA_LIBRARY_PATH}" ]
	then
		print_err "invalid JAVA_LIBRARY_PATH"
		exit 1
	fi
}

function tools_check
{
	print_task "tools_check"
	#which find >/dev/null
	which "$JAVA" >/dev/null
	which "$JAVAC" >/dev/null
	which "$JAR" >/dev/null
	which "$JLINK" >/dev/null
	which "$JDEPS" >/dev/null
	which chmod >/dev/null
	which mkdir >/dev/null
	which cp >/dev/null
	which rm >/dev/null
	which mv >/dev/null
	which makeself >/dev/null
	which tar >/dev/null
	"$JAVA" -version
}

function clean_build_env
{
	print_task "clean_build_env"
	mkdir -p "$BUILD"
	rm -rf "$BUILD"/*
	mkdir -p "$DIST"
	rm -rf "$DIST"/*
}

function build_app
{
	cd "$BUILD"
	print_task "build_app $APP_NAME"
	mkdir -p classes
	rm -rf classes/*
	"$JAVAC" -cp "${CP}" -d classes ../src/t/EventTest.java
}

function build_flat_jar
{
	cd "$BUILD"
	print_task "build_flat_jar"
	mkdir -p flatjar
	rm -rf flatjar/*

	#copy all jars/classes
	cp ${JOGL_ALL_JAR} flatjar
	cp ${GLUEGEN_RT_JAR} flatjar	
	cp -r classes/* flatjar

	cd flatjar
	mkdir META-INF_
	#unpack
	"$JAR" xf jogl*.jar
	#save META-INFs
	mv META-INF META-INF_/META-INF_jogl
	"$JAR" xf gluegen*.jar
	mv META-INF META-INF_/META-INF-gluegen-rt
	#remove jars
	rm jogl*.jar gluegen*.jar

	#find | grep /windows/
	#find jogamp/ | grep /windows/|while read line; do rm -rf "$line"; done
	#find jogamp/ | grep /macosx/|while read line; do rm -rf "$line"; done

	#remove swt related (otherwise unresolved dependencies on jlink step)
	rm -rf com/jogamp/nativewindow/swt
	rm -rf com/jogamp/newt/swt
	rm -rf com/jogamp/opengl/swt
	rm -rf jogamp/newt/swt
	rm -rf jogamp/opengl/openal/av

	rm -rf jogl
	rm -rf gluegen
	rm -rf newt

	#create new jar containing current directory contents (no module-info involved)
	"$JAR" cf "$MODULE_NAME".jar *
}

function modularize_jar
{
	print_task "modularize_jar"
	cd "$BUILD"
	mkdir -p modules

	cd flatjar

#	print_task "generating module-info"
	#creates file in folder app/module-info.java
	"$JDEPS" --generate-module-info . "$MODULE_NAME".jar
#	ls -ltr

#	print_task "compiling module-info"
	"$JAVAC" -d . "$MODULE_NAME"/module-info.java

#	print_task "update modularize legacy jar"
	"$JAR" fu "$MODULE_NAME".jar module-info.class
	#copy final modularized jar to output
	mv "$MODULE_NAME".jar ../modules
}

function create_runtime_image
{
	print_task "create_runtime_image"
	cd "$BUILD"

	rm -rf "$OUT_IMAGE_NAME"

	$JLINK --compress 2 \
		--module-path "modules:${JAVA_HOME}/jmods" \
		--add-modules "$MODULE_NAME" \
		--output "$OUT_IMAGE_NAME"

	cd "$OUT_IMAGE_NAME"

	mkdir natives
	touch natives/JOGL_LIBS
	cp -r "$JAVA_LIBRARY_PATH" natives

	rm "bin/appletviewer"
	rm "bin/keytool"
	rm -rf "conf/security/policy/"

	#write start script
	echo "#!/bin/bash" > start.sh
	echo "#cd to root of image" >> start.sh
	echo "cd \"\$(dirname \${BASH_SOURCE[0]})\"" >> start.sh
	echo "./bin/java -m ${STARTUP_STRING}" \$@ >> start.sh
	chmod 755 start.sh
}

function create_makeself_image
{
	print_task "create_makeself_image"
	cd "$BUILD"

	makeself -q "$OUT_IMAGE_NAME" "$DIST"/"$OUT_IMAGE_NAME".sh "$APP_TITLE" ./start.sh
	chmod 755 "$DIST"/"$OUT_IMAGE_NAME".sh 

#	print_task "creating tarball"
	cd "$DIST"
	tar cfz "$OUT_IMAGE_NAME".tgz "$OUT_IMAGE_NAME".sh

	ls -1 "$DIST"/"$OUT_IMAGE_NAME".sh >/dev/null
	echo "$DIST"/"$OUT_IMAGE_NAME".sh
}

#==============================================================================
#==============================================================================

path_check
tools_check
clean_build_env
build_app
build_flat_jar
modularize_jar
create_runtime_image
create_makeself_image

cd "$DIR"
trap : 0
echo "done."
exit 0
#EOF
