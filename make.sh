#!/bin/bash

#//tb/1710

DIR="$(dirname ${BASH_SOURCE[0]})"
cd "$DIR"
DIR="`pwd`"
echo $DIR

#pre-requisite: find and download jogamp-all-platforms.7z and decompress with 7zr
#then set path accordingly here
PATH_TO_JOGAMP_ALL_PLATFORMS="$DIR/jogamp-all-platforms"

JOGL_ALL_JAR="${PATH_TO_JOGAMP_ALL_PLATFORMS}/jar/jogl-all.jar"
GLUEGEN_RT_JAR="${PATH_TO_JOGAMP_ALL_PLATFORMS}/jar/gluegen-rt.jar"

CP=".:classes:${JOGL_ALL_JAR}:${GLUEGEN_RT_JAR}"

JAVA_LIBRARY_PATH="${PATH_TO_JOGAMP_ALL_PLATFORMS}/lib/linux-amd64/"
#JAVA_LIBRARY_PATH="${PATH_TO_JOGAMP_ALL_PLATFORMS}/lib/macosx-universal/"
#JAVA_LIBRARY_PATH="${PATH_TO_JOGAMP_ALL_PLATFORMS}/lib/windows-amd64/"

OUT_JAR_NAME="jogl_app_linux64.jar"
#OUT_JAR_NAME="jogl_app_mac.jar"
#OUT_JAR_NAME="jogl_app_win64.jar"

jsource=1.6
jtarget=1.6
JAVAC="javac -source $jsource -target $jtarget -nowarn"

#tool check here ...
#java, javac, jar

#file / dir existence check
if [ ! -d "${PATH_TO_JOGAMP_ALL_PLATFORMS}" ]
then
	echo "invalid PATH_TO_JOGAMP_ALL_PLATFORMS"
	exit 1
fi
if [ ! -f "${JOGL_ALL_JAR}" ]
then
	echo "invalid JOGL_ALL_JAR"
	exit 1
fi
if [ ! -f "${GLUEGEN_RT_JAR}" ]
then
	echo "invalid GLUEGEN_RT_JAR"
	exit 1
fi
if [ ! -d "${JAVA_LIBRARY_PATH}" ]
then
	echo "invalid JAVA_LIBRARY_PATH"
	exit 1
fi

function build_app
{
	echo "building app (EventTest)"
	mkdir -p classes
	rm -rf classes/*
	$JAVAC -cp "${CP}" -d classes ../src/t/*.java ../src/com/jdotsoft/jarloader/JarClassLoader.java
}

#takes arg: FPS
function test_run_app
{
	echo "running app (EventTest)"
	echo "java -Djava.library.path=${JAVA_LIBRARY_PATH} -cp ${CP} t.EventTest"
	java -Djava.library.path="${JAVA_LIBRARY_PATH}" -cp "${CP}" t.EventTest $1
}

function build_self_contained_jar
{
	echo "building self-contained jar"

	mkdir -p singlejar
	rm -rf singlejar/*
	#copy invovled dependencies (jars, shared objects)
	#JarClassLoader will handle class loading (jar inside jar, .so inside jar etc)
	#see src/Launcher.java
	cp ${JOGL_ALL_JAR} singlejar
	cp ${GLUEGEN_RT_JAR} singlejar
	cp -r ${JAVA_LIBRARY_PATH}/* singlejar
	#copy compiled sources (EventTest, Launcher)
	cp -r classes/* singlejar

	#create jar
	cd singlejar
	jar cfm ../../_dist/${OUT_JAR_NAME} ../../src/Manifest.txt *
	cd ..
	echo "done."
	echo "try running the app:"
	echo "java -jar _dist/${OUT_JAR_NAME} 60"
}

#==============================================================================

mkdir -p _build
rm -rf _build/*
mkdir -p _dist
rm -rf _dist/*
cd _build

build_app
#test_run_app $1
build_self_contained_jar
