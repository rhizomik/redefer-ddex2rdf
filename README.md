# ReDeFer ddex2rdf

Convert DDEX into RDF using Web Ontologies (schema.org, Copyright Ontology,...).

Currently supporting:
 * DDEX ERN
 
## Web API

Start Web service:

```bash
java -jar target/ddex2rdf.jar
```

Explore and use API by browsing http://localhost:8080

## Command Line Interface

Run from command line:

```bash
java -jar target/ddex2rdf.jar ddex2rdf
```

Example to convert single DDEX XML file and get RDF in standard output:

```bash
java -jar target/ddex2rdf.jar ddex2rdf -i ddex.xml -o
```

Example to convert all DDEX XML files in the input folder and get the output for each of them 
in the corresponding XML_FILE_NAME.rdf files:

```bash
java -jar target/ddex2rdf.jar ddex2rdf -i ddex-samples/
```

## Build

To build `target/ddex2rdf.jar`:

```bash
mvn package
```