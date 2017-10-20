# jogl_single_jar

```
Get jogamp libraries (jogl-all.jar, gluegen-rt.jar, shared libraries, ...):

https://jogamp.org/deployment/jogamp-current/archive/jogamp-all-platforms.7z

Uncompress with 7zr then adjust make.sh with the according path.

----

(https://www.chilkatsoft.com/java-loadLibrary-Linux.asp)

How to Load a Java Native/Shared Library (.so)

There are several ways to make it possible for the Java runtime to find and load a native shared library (.so) at runtime. I will list them briefly here, followed by examples with more explanation below.

1)    Call System.load to load the .so from an explicitly specified absolute path.
2)    Copy the shared library to one of the paths already listed in java.library.path
3)    Modify the LD_LIBRARY_PATH environment variable to include the directory where the shared library is located.
4)    Specify the java.library.path on the command line by using the -D option.

----

(http://www.jdotsoft.com/JarClassLoader.php)

The class loader to load classes, native libraries and resources from the top JAR and from JARs inside the top JAR.

```
