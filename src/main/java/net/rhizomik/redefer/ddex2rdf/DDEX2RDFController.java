package net.rhizomik.redefer.ddex2rdf;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import javax.xml.xquery.XQException;
import java.io.IOException;
import java.net.URL;

/**
 * Created by http://rhizomik.net/~roberto/
 */
@Controller
public class DDEX2RDFController {

    @Autowired DDEX2RDFService ddex2RDFService;

    @RequestMapping(value = "/map", method = RequestMethod.GET, produces = MediaType.APPLICATION_XML_VALUE)
    public HttpEntity<byte[]> ddexUrl2Rdf(@RequestParam(value="url") String url) throws IOException, XQException {
        String xmlRdf = ddex2RDFService.XMLURLtoRDF(new URL(url));
        return getHttpEntity(xmlRdf);
    }

    @RequestMapping(value = "/map", method = RequestMethod.POST,
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_XML_VALUE)
    public HttpEntity<byte[]> ddexForm2Rdf(@RequestParam(value="xml") String xml) throws IOException, XQException {
        String xmlRdf = ddex2RDFService.XMLtoRDF(xml);
        return getHttpEntity(xmlRdf);
    }

    @RequestMapping(value = "/map", method = RequestMethod.POST,
            consumes = MediaType.APPLICATION_XML_VALUE, produces = MediaType.APPLICATION_XML_VALUE)
    public HttpEntity<byte[]> ddexXml2Rdf(@RequestBody String xml) throws IOException, XQException {
        String xmlRdf = ddex2RDFService.XMLtoRDF(xml);
        return getHttpEntity(xmlRdf);
    }

    private HttpEntity<byte[]> getHttpEntity(String xmlRdf) {
        byte[] xmlRdfBody = xmlRdf.getBytes();
        HttpHeaders header = new HttpHeaders();
        header.setContentType(new MediaType("application", "xml"));
        header.setContentLength(xmlRdfBody.length);
        return new HttpEntity<>(xmlRdfBody, header);
    }
}