xquery version "1.0";

declare namespace ddex ="http://rhizomik.net/ontologies/2011/06/ddex.owl#";
declare namespace owl ="http://www.w3.org/2002/07/owl#";
declare namespace rdfs ="http://www.w3.org/2000/01/rdf-schema#";
declare namespace rdf ="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace xs ="http://www.w3.org/2001/XMLSchema";

declare variable $file external;
(:declare variable $file := "../DDEX-ERNM+DSRM-32-XSD/ddex.xsd";:)

<rdf:RDF xmlns:ddex="http://rhizomik.net/ontologies/2011/06/ddex.owl#"
         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xml:base="http://rhizomik.net/ontologies/2011/06/ddex.owl">
    <owl:Ontology rdf:about="">
      <rdfs:comment>OWL ontology containing classes for the simpleTypes in ddex.xsd and subclasses of them for their enumerated values</rdfs:comment>
    </owl:Ontology>
        {
            for $topClass in doc($file)/xs:schema/xs:simpleType
            return (<owl:Class rdf:ID="{$topClass/@name}">
                        <rdfs:comment>{data($topClass/xs:annotation/xs:documentation)}</rdfs:comment>
                    </owl:Class>,
                for $subClass in $topClass//xs:enumeration
                return (
                    <owl:Class rdf:ID="{$subClass/@value}">
                        <rdfs:subClassOf rdf:resource="#{$topClass/@name}"/>
                    </owl:Class>,
                    <rdf:Description rdf:ID="{$subClass/@value}Value">
                        <rdf:type rdf:resource="#{$subClass/@value}"/>
                    </rdf:Description>)
                )
        }
</rdf:RDF>