package net.rhizomik.redefer.ddex2rdf;

import net.rhizomik.util.file.FileManagement;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.xml.namespace.QName;
import javax.xml.xquery.*;
import java.io.*;
import java.net.URL;
import java.util.Properties;
import java.util.logging.Logger;

@Service
public class DDEX2RDFService {
    private static final Logger log = Logger.getLogger(DDEX2RDFService.class.getName());

    static String rdfHead = "<rdf:RDF\n" +
            " xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n" +
            " xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"\n" +
            " xmlns:owl=\"http://www.w3.org/2002/07/owl#\"\n" +
            " xmlns:ddex=\"http://rhizomik.net/ontologies/2011/06/ddex.owl#\"\n" +
            " xmlns:currency=\"http://rhizomik.net/ontologies/2011/06/iso4217a.owl#\"\n" +
            " xmlns:territory=\"http://rhizomik.net/ontologies/2011/06/iso3166a2.owl#\"\n" +
            " xmlns:language=\"http://rhizomik.net/ontologies/2011/06/iso639a2.owl#\"\n" +
            " xmlns:cro=\"http://rhizomik.net/ontologies/copyrightonto.owl#\"\n" +
            " xmlns:dct=\"http://purl.org/dc/terms/\"\n" +
            " xmlns:ma=\"http://www.w3.org/ns/ma-ont#\">\n";
    static String rdfFoot = "\n</rdf:RDF>";

    XQPreparedExpression xquery;

    private static Properties getSerializationProperties() {
        Properties serializationProps = new Properties();
        serializationProps.setProperty("method", "xml");
        serializationProps.setProperty("indent", "yes");
        serializationProps.setProperty("encoding", "UTF-8");
        serializationProps.setProperty("omit-xml-declaration", "yes");
        return serializationProps;
    }

    @Autowired
    DDEX2RDFService(@Value("${net.rhizomik.redefer.ddex2rdf.xquery}") String xqueryFile)
            throws XQException, InstantiationException, IllegalAccessException, ClassNotFoundException, FileNotFoundException {
        prepareXquery(this.getClass().getResourceAsStream(xqueryFile));
    }

    DDEX2RDFService(File xqueryFile)
            throws XQException, InstantiationException, IllegalAccessException, ClassNotFoundException, FileNotFoundException {
        prepareXquery(new FileInputStream(xqueryFile));
    }

    public String XMLFiletoRDF(File file, String pathOrURL) throws XQException, UnsupportedEncodingException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        xquery.bindString(new QName("file"), file.getAbsolutePath(), null);
        xquery.bindString(new QName("fullPath"), pathOrURL, null);
        XQResultSequence rs = xquery.executeQuery();

        rs.writeSequence(out, getSerializationProperties());
        rs.close();

        return out.toString("UTF8");
    }

    public String XMLURLtoRDF(URL url) throws XQException, IOException
    {
        String localFileName = url.getFile().substring(url.getFile().lastIndexOf('/') + 1, url.getFile().length());
        File local = new File(localFileName);
        local.createNewFile();
        FileManagement.saveToFile(url.openConnection().getInputStream(), local);
        String rdf = XMLFiletoRDF(local, url.toString());
        local.delete();
        return addRDFHeadAndFoot(rdf);
    }

    public String XMLtoRDF(String ddexXML) throws XQException, IOException
    {
        File local = File.createTempFile("ddex", "xml");
        FileManagement.saveToFile(new ByteArrayInputStream(ddexXML.getBytes()), local);
        String rdf = XMLFiletoRDF(local, local.getAbsolutePath());
        local.delete();
        return addRDFHeadAndFoot(rdf);
    }

    private void prepareXquery(InputStream xqueryStream) throws ClassNotFoundException, XQException, IllegalAccessException, InstantiationException {
        XQDataSource xqds = (XQDataSource) Class.forName("com.saxonica.xqj.SaxonXQDataSource").newInstance();
        XQConnection con = xqds.getConnection();
        xquery = con.prepareExpression(xqueryStream);
    }

    protected String addRDFHeadAndFoot(String rdfFragment) {
        return rdfHead + rdfFragment + rdfFoot;
    }
}
