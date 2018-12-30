declare namespace schema= "http://schema.org/";
declare namespace cro=    "http://rhizomik.net/ontologies/copyrightonto.owl#";
declare namespace rdf=    "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs=   "http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl=    "http://www.w3.org/2002/07/owl#";
declare namespace dct=    "http://purl.org/dc/terms/";
declare namespace xsd=    "http://www.w3.org/2001/XMLSchema#";

declare variable $schema := "http://schema.org/";
declare variable $cro := "http://rhizomik.net/ontologies/copyrightonto.owl#";
declare variable $rdf := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare variable $baseURI := "http://rhizomik.net/redefer/ddex2rdf/";
declare variable $file external;
declare variable $base := concat($baseURI,local:filename($file));
(: let $file := "src/main/resources/static/ddex-samples/Sample-08.04.xml" :)

declare function local:filename($arg as xs:string?) as xs:string
{       
    replace($arg,'^.*/','')
};

declare function local:baseURI($localId as xs:string) as xs:string
{
    let $baseURI := concat($base,'#',$localId)
    return ($baseURI)
};

declare function local:getResourceURI($localId as xs:string) as xs:string
{
    let $resource := doc($file)//ResourceList/*[ResourceReference=$localId]
    
    let $resourceURI :=
        if ($resource/*/ISRC) then concat("urn:isrc:",data($resource/*/ISRC))
        else if ($resource/*/ISBN) then concat("urn:isbn:",data($resource/*/ISBN))
        else if ($resource/*/ISSN) then concat("urn:issn:",data($resource/*/ISSN))
        else if ($resource/*/SICI) then concat("urn:sici:",data($resource/*/SICI))
        else if ($resource/*/ISAN) then concat("urn:isan:",data($resource/*/ISAN))
        else if ($resource/*/VISAN) then concat("urn:visan:",data($resource/*/VISAN))
        else if ($resource/*/CatalogNumber) then concat("urn:catalog:",data($resource/*/CatalogNumber)) 
        else if ($resource/*/ProprietaryId) then concat("urn:",$resource/*/ProprietaryId/@Namespace,":",data($resource/*/ProprietaryId))
        else local:baseURI($localId)
    return ($resourceURI)
};

declare function local:getPartyDescription($party)
{
    let $name := $party/PartyName/FullName/text()
    let $uri := concat("urn:", $party/PartyId/@Namespace, "/", $party/PartyId/text())
    return
    <rdfs:Resource rdf:about="{$uri}">
        <schema:name>{data($name)}</schema:name>
    </rdfs:Resource>
};


declare function local:buildResource($uri, $label, $type)
{
    <rdfs:Resource rdf:about="{$uri}">
        <rdfs:label>{data($label)}</rdfs:label>
        <rdf:type rdf:resource="{$type}"/>
    </rdfs:Resource>
};

declare function local:buildLabelResource($label, $kind, $type)
{
    let $uri := concat($baseURI,$kind,"/",encode-for-uri($label))
    return
        local:buildResource($uri,$label,$type)
};

declare function local:buildLabelURI($label, $kind)
{
    let $uri := concat($baseURI,$kind,"/",encode-for-uri($label))
    return $uri
};

for $resource at $i in doc($file)//ResourceList/SoundRecording
    let $resourceId := local:getResourceURI(data($resource/ResourceReference))
    let $resourceDetails := $resource/*[contains(local-name(.),"DetailsByTerritory")][1]
    let $technicalDetails := $resourceDetails/*/TechnicalResourceDetailsReference/..
    return
    <schema:MusicRecording rdf:about="{$resourceId}">
        { if ($resource/*/ISRC) then <schema:identifier>{data($resource/*/ISRC)}</schema:identifier> else () }
        { if ($resource/*/ISBN) then <schema:identifier>{data($resource/*/ISBN)}</schema:identifier> else () }
        { if ($resource/*/ISSN) then <schema:identifier>{data($resource/*/ISSN)}</schema:identifier> else () }
        { if ($resource/*/SICI) then <schema:identifier>{data($resource/*/SICI)}</schema:identifier> else () }
        { if ($resource/*/ISAN) then <schema:identifier>{data($resource/*/ISAN)}</schema:identifier> else () }
        { if ($resource/*/VISAN) then <schema:identifier>{data($resource/*/VISAN)}</schema:identifier> else () }
        { if ($resource/*/CatalogNumber) then <schema:identifier>{data($resource/*/CatalogNumber)}</schema:identifier> else () }
        { if ($resource/*/ProprietaryId) then <schema:identifier>{data($resource/*/ProprietaryId/@Namespace)}-{data($resource/*/ProprietaryId)}</schema:identifier> else () }
        { for $title in $resource/(ReferenceTitle|Title)/TitleText
            return <schema:name>{data($title)}</schema:name> }
        { for $altTitle in $resource/(ReferenceTitle|Title)/SubTitle 
            return <schema:alternativeHeadline>{data($altTitle)}</schema:alternativeHeadline> }
        { for $duration in $resource/Duration 
            return <schema:duration>{data($duration)}</schema:duration> }
        { for $language in $resource/LanguageOfPerformance 
            return <schema:inLanguage>{data($language)}</schema:inLanguage> }
        { for $creator in $resourceDetails/DisplayArtist 
            return <schema:creator>{local:getPartyDescription($creator)}</schema:creator> }
        { for $copyrightYear in $resourceDetails/(CLine|PLine)/Year
            return <schema:copyrightYear>{data($copyrightYear)}</schema:copyrightYear> }
        { for $copyright in $resourceDetails/(CLine|PLine)/(CLineText|PLineText)
            return <dct:copyright>{data($copyright)}</dct:copyright> }
        { for $label in distinct-values($resourceDetails/LabelName)
            return <schema:recordLabel>{data($label)}</schema:recordLabel> }
        { for $genre in $resourceDetails/Genre/GenreText
            return <schema:genre>{data($genre)}</schema:genre> }
        { for $parental in $resourceDetails/ParentalWarningType
            return <schema:contentRating>{data($parental)}</schema:contentRating> }
    </schema:MusicRecording>