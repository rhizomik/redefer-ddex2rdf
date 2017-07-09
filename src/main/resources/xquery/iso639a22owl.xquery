xquery version "1.0";

declare namespace iso639a2 ="http://rhizomik.net/ontologies/2011/06/iso639a2.owl#";
declare namespace owl ="http://www.w3.org/2002/07/owl#";
declare namespace rdfs ="http://www.w3.org/2000/01/rdf-schema#";
declare namespace rdf ="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace xs ="http://www.w3.org/2001/XMLSchema";

declare variable $file external;
(:declare variable $file := "../DDEX-ERNM+DSRM-32-XSD/iso639a2.xsd";:)

<rdf:RDF xmlns:iso639a2="http://rhizomik.net/ontologies/2011/06/iso639a2.owl#"
         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:owl="http://www.w3.org/2002/07/owl#"
         xml:base="http://rhizomik.net/ontologies/2011/06/iso639a2.owl">
    <owl:Ontology rdf:about="">
      <rdfs:comment>OWL ontology containing classes for the simpleTypes in iso639a2.xsd and subclasses of them for their enumerated values</rdfs:comment>
    </owl:Ontology>
        {
            for $class in doc($file)/xs:schema/xs:simpleType
            return (<owl:Class rdf:ID="{$class/@name}">
                        <rdfs:comment>{data($class/xs:annotation/xs:documentation)}</rdfs:comment>
                    </owl:Class>,
                for $instance in $class//xs:enumeration
                return 
                    <rdf:Description rdf:ID="{$instance/@value}">
                        <rdf:type rdf:resource="#{$class/@name}"/>
                        <rdfs:label>{data($instance/xs:annotation/xs:documentation)}</rdfs:label>
                    </rdf:Description> )
        }
</rdf:RDF>