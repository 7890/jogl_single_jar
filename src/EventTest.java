//http://forum.jogamp.org/Newt-event-handling-td4026877.html
//http://pastebin.com/wJ3wHFU1
//"Hi, I'm trying to get my head around the event handling mechanism in NEWT, but haven't been very successful so far. The general situation is as follows: I create a GLWindow, and then wrap it with a NewtCanvasAWT in order to add it to an AWT frame. My problem is how to implement working mouse and key listeners."

//add KeyListener
//tb/1710

import java.awt.BorderLayout;
import java.awt.EventQueue;
import java.awt.Frame;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.lang.reflect.InvocationTargetException;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GLAnimatorControl;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.GLCapabilities;
import com.jogamp.opengl.GLEventListener;
import com.jogamp.opengl.GLProfile;

import com.jogamp.newt.event.MouseEvent;
import com.jogamp.newt.event.KeyEvent;
import com.jogamp.newt.event.MouseAdapter;
import com.jogamp.newt.event.MouseListener;
import com.jogamp.newt.event.KeyAdapter;
import com.jogamp.newt.event.KeyListener;

import com.jogamp.newt.opengl.GLWindow;
import com.jogamp.opengl.util.Animator;
import com.jogamp.opengl.util.FPSAnimator;
import com.jogamp.newt.awt.NewtCanvasAWT;

public class EventTest
{
	Frame frame;
	GLWindow window;
	NewtCanvasAWT canvas;
	float theta = 0;
	int fps=25;

	public EventTest(){}
	public EventTest(int fps){this.fps=fps;}

	public static void main(String[] args)
	{
		EventTest test;
		if(args.length==1)
		{
			test=new EventTest(Integer.parseInt(args[0]));
		}
		else
		{
			test=new EventTest(25);
		}

		try
		{
			test.run();
		} catch (Exception e)
		{
			e.printStackTrace();
		}
	}

	void draw(GL2 gl)
	{
		gl.glClearColor(0, 0, 0, 1);
		gl.glClear(GL.GL_COLOR_BUFFER_BIT);
		theta += 0.01;
		double s = Math.sin(theta);
		double c = Math.cos(theta);

		gl.glBegin(GL.GL_TRIANGLES);
		gl.glColor3f(1, 0, 0);
		gl.glVertex2d(-c, -c);
		gl.glColor3f(0, 1, 0);
		gl.glVertex2d(0, c);
		gl.glColor3f(0, 0, 1);
		gl.glVertex2d(s, -s);
		gl.glEnd();
		gl.glFlush();
	}

	public void run() throws InterruptedException, InvocationTargetException
	{
		frame = new Frame("AWT Frame");

		GLProfile profile = GLProfile.getDefault();
		GLCapabilities capabilities = new GLCapabilities(profile);

		window = GLWindow.create(capabilities);
		canvas = new NewtCanvasAWT(window);
		canvas.setBounds(0, 0, 300, 300);
		canvas.setFocusable(true);

		MouseListener mouseListener = new TestMouseAdapter();
		window.addMouseListener(mouseListener);

		KeyListener keyListener = new TestKeyAdapter();
		window.addKeyListener(keyListener);

		frame.setLayout(new BorderLayout());
		frame.add(canvas, BorderLayout.CENTER);

		TestGLListener glListener = new TestGLListener();
		window.addGLEventListener(glListener);
//		final GLAnimatorControl animator = new Animator(window);
		final FPSAnimator animator = new FPSAnimator(window, fps, true);

		animator.start();

		frame.setLocation(0, 0);
		frame.setSize(300, 300);
		frame.addWindowListener(new WindowAdapter()
		{
			public void windowClosing(WindowEvent e)
			{
				animator.stop();
				System.exit(0);
			}
		});

		EventQueue.invokeAndWait(new Runnable()
		{
			public void run()
			{
				frame.validate();
				frame.setVisible(true);
			}
		});
	}//end run()

	//inner classes

	class TestGLListener implements GLEventListener
	{
		public void display(GLAutoDrawable drawable)
		{
			draw(drawable.getGL().getGL2());
		}
		public void dispose(GLAutoDrawable drawable) { }
		public void init(GLAutoDrawable drawable) { }
		public void reshape(GLAutoDrawable drawable, int x, int y, int w, int h) { }
	}

	class TestMouseAdapter extends MouseAdapter
	{
		public void mousePressed(MouseEvent e)
		{
			System.out.println("mouse pressed event: " + e);
		}
		public void mouseReleased(MouseEvent e)
		{
			System.out.println("mouse released event: " + e);
		}
		public void mouseMoved(MouseEvent e)
		{
			System.out.println("mouse moved event: " + e);
		}
		public void mouseDragged(MouseEvent e)
		{
			System.out.println("mouse dragged event: " + e);
		}
	}

	class TestKeyAdapter extends KeyAdapter
	{
		public void keyPressed(KeyEvent e)
		{
			System.out.println("key pressed event: " + e);
		}
		public void keyReleased(KeyEvent e)
		{
			System.out.println("key released event: " + e);
		}
	}

}//end class EventTest
