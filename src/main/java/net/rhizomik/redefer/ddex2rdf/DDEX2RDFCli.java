package net.rhizomik.redefer.ddex2rdf;

import javax.xml.xquery.XQException;
import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Created by http://rhizomik.net/~roberto/
 */
public class DDEX2RDFCli {
    private static final Logger log = Logger.getLogger(DDEX2RDFCli.class.getName());

    public static void main(String[] args)
            throws XQException, InstantiationException, IllegalAccessException, ClassNotFoundException, IOException {

        if (args.length < 2) {
            System.err.println("$> DDEX2RDFCli XQueryPath XMLFilePath|XMLFolderPath [OutputRDFFile] ");
            System.exit(-1);
        }

        DDEX2RDFService ern2rdf = new DDEX2RDFService(new File(args[0]));

        String rdf = "";
        File input = new File(args[1]);
        if (input.isDirectory())
            for (File f : input.listFiles(new XMLFileFilter()))
            {
                log.log(Level.INFO, "Processing file: " + f);
                rdf += ern2rdf.XMLFiletoRDF(f, f.getAbsolutePath());
            }
        else
            rdf += ern2rdf.XMLFiletoRDF(input, input.getAbsolutePath());

        rdf = ern2rdf.addRDFHeadAndFoot(rdf);

        if (args.length > 2) {
            PrintWriter out = new PrintWriter(args[2]);
            out.println(rdf);
            out.close();
        } else
            System.out.println(rdf);
    }

    private static class XMLFileFilter implements FilenameFilter {

        public boolean accept(File file, String fileName) {
            return fileName.endsWith(".xml");
        }
    }
}
