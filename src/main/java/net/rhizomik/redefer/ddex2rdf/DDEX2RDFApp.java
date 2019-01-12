package net.rhizomik.redefer.ddex2rdf;

import java.io.File;
import java.io.PrintWriter;
import java.util.Collection;
import java.util.Collections;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.io.FileUtils;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DDEX2RDFApp {

	public static void main(String[] args) {
		if (args.length > 0 && args[0].equalsIgnoreCase("ddex2rdf"))
			cli(args);
		else
			SpringApplication.run(DDEX2RDFApp.class, args);
	}

	private static void cli(String[] args) {
		HelpFormatter formatter = new HelpFormatter();
		CommandLineParser parser = new DefaultParser();

		Options options = new Options();
		options.addOption(Option.builder("x").longOpt("xquery")
			.desc("XQuery resource to use if different from the default one:"
				+ " '/xquery/query-ern-cro_schema.xquery'")
			.hasArg().numberOfArgs(1).argName("XQuery")
			.build());
		options.addOption(Option.builder("i").longOpt("input")
			.desc("input XML file or folder, which will be scanned to process multiple .xml files"
				+ " including subfolders")
			.hasArg().numberOfArgs(1).argName("File|Folder")
			.required().build());
		options.addOption("o", "output", false, "sends resulting RDF"
			+ " to standard output instead of storing it in the corresponding XMLFILENAME.rdf");

		try {
			CommandLine line = parser.parse(options, args);

			String xqFile = "/xquery/query-ern-cro_schema.xquery";
			if (line.hasOption("xquery"))
				xqFile = line.getOptionValue("xquery");

			DDEX2RDFService ern2rdf = new DDEX2RDFService(xqFile);

			File input = new File(line.getOptionValue("input"));
			Collection<File> files = Collections.singleton(input);
			if (input.isDirectory()) {
				String[] extensions = {"xml"};
				files = FileUtils.listFiles(input, extensions, true);
			}
			if (line.hasOption("output")) {
				System.out.println(DDEX2RDFService.rdfHead);
				for(File file: files)
					System.out.println(ern2rdf.XMLFiletoRDF(file, file.getAbsolutePath()));
				System.out.println(DDEX2RDFService.rdfFoot);
			} else {
				for (File file: files) {
					System.out.println("Processing file: " + file);
					String rdf = ern2rdf.XMLFiletoRDF(file, file.getAbsolutePath());
					rdf = ern2rdf.addRDFHeadAndFoot(rdf);
					String rdfFile =
						file.getPath().substring(0, file.getPath().lastIndexOf(".xml")) + ".rdf";
					PrintWriter out = new PrintWriter(rdfFile);
					out.println(rdf);
					out.close();
					System.out.println("Wrote RDF to file: " + rdfFile);
				}
			}
		}
		catch(ParseException e ) {
			System.out.println("Error: " + e.getMessage() + "\n");
			formatter.printHelp("ddex2rdf -i <File|Folder> [OPTIONS]", options);
		}
		catch (Exception e) {
			System.out.println("Error: " + e.getMessage() + "\n");
		}
	}
}
