import com.jdotsoft.jarloader.JarClassLoader;

//wrapper to put inside jar, calling main application via jcl

public class Launcher
{
	public static void main(String[] args)
	{
		JarClassLoader jcl = new JarClassLoader();
		try
		{
			jcl.invokeMain("EventTest", args);
		}
		catch (Throwable e)
		{
			e.printStackTrace();
		}
	}
}
//eof
