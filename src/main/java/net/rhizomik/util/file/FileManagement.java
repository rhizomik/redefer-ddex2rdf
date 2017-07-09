package net.rhizomik.util.file;

import java.io.*;

/**
 * Created by http://rhizomik.net/~roberto/
 */
public class FileManagement {

    public static void saveToFile(InputStream input, File local) throws IOException {
        BufferedOutputStream localOut = new BufferedOutputStream(new FileOutputStream(local));
        BufferedInputStream in = new BufferedInputStream(input);
        byte[] buffer = new byte[1024];
        int read = in.read(buffer);
        while (read > 0) {
            localOut.write(buffer, 0, read);
            read = in.read(buffer);
        }
        localOut.close();
    }

    public static String loadFile(String filename) throws IOException {
        BufferedInputStream input = new BufferedInputStream(new FileInputStream(filename)); //ClassLoader.getSystemResourceAsStream(filename));
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        byte[] buffer = new byte[1024];
        int read = input.read(buffer);
        while (read > 0) {
            out.write(buffer, 0, read);
            read = input.read(buffer);
        }
        out.flush();
        return out.toString("UTF8");
    }
}
